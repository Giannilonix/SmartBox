// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:finale_app/Message.dart';
import 'package:finale_app/database_helper.dart';
import 'dart:collection';
import 'package:finale_app/secondpage.dart';


Future<void> main() async {
  //WidgetsFlutterBinding.ensureInitialized(); //forse non serve per l'esempio
  //await DBHelper().initDatabase();
  //final dbHelper = DatabaseHelper.instance;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();

}

class _BluetoothAppState extends State<BluetoothApp> {

  final dbHelper = DatabaseHelper.instance;
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;


  int _deviceState;
  int _logState = 0;

  var _prova;
  var test = false;
  var _temp;
  var _message = '';
  bool isDisconnecting = false;
  final myController = TextEditingController();
  var _splitted = [];
  Queue<String> buffer = new Queue<String>();

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    myController.dispose();
    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }


  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("SmartBox Home"),
          backgroundColor: Colors.blueAccent,
          actions: <Widget>[
            FlatButton.icon(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: Text(
                "Refresh",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              splashColor: Colors.greenAccent,
              onPressed: () async {
                // So, that when new devices are paired
                // while the app is running, user can refresh
                // the paired devices list.
                await getPairedDevices().then((_) {
                  show('Device list refreshed');
                });
              },
            ),
          ],
        ),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Visibility(
                visible: _isButtonUnavailable &&
                    _bluetoothState == BluetoothState.STATE_ON,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.yellow,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Enable Bluetooth',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        future() async {
                          if (value) {
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          } else {
                            await FlutterBluetoothSerial.instance
                                .requestDisable();
                          }

                          await getPairedDevices();
                          _isButtonUnavailable = false;

                          if (_connected) {
                            _disconnect();
                          }
                        }

                        future().then((_) {
                          setState(() {});
                        });
                      },
                    )
                  ],
                ),
              ),
              Divider(),
              Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "PAIRED DEVICES",
                          style: TextStyle(fontSize: 20, color: Colors.blue),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Device:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton(
                              items: _getDeviceItems(),
                              onChanged: (value) =>
                                  setState(() => _device = value),
                              value: _devicesList.isNotEmpty ? _device : null,
                            ),
                            RaisedButton(
                              onPressed: _isButtonUnavailable
                                  ? null
                                  : _connected ? _disconnect : _connect,
                              child:
                              Text(_connected ? 'Disconnect' : 'Connect'),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: new BorderSide(
                              color: _deviceState == 0
                                  ? colors['neutralBorderColor']
                                  : _deviceState == 1
                                  ? colors['onBorderColor']
                                  : colors['offBorderColor'],
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          elevation: _deviceState == 0 ? 4 : 0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "LOG",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: _deviceState == 0
                                          ? colors['neutralTextColor']
                                          : _deviceState == 1
                                          ? colors['onTextColor']
                                          : colors['offTextColor'],
                                    ),
                                  ),
                                ),
                                FlatButton(
                                  onPressed: _connected
                                      ? _logOn
                                      : null,
                                  child: Text("ON"),
                                ),
                                FlatButton(
                                  onPressed: _connected
                                      ? _logOff
                                      : null,
                                  child: Text("OFF"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  /* Container(
                    color: Colors.blue,
                  ),*/
                ],
              ),
              Divider(),
              Text(
                'Dati: $_prova',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 8,
              ),
              Divider(),
               // ignore: deprecated_member_use
              ElevatedButton(
                child: Text('Go to Graph'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondRoute()),
                      //MaterialPageRoute(builder: (context) => LineChartSample2()),

                  );
                },
              ),
              Divider(),
            ],
          ),

        ),

      ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          connection = _connection;
          setState(() {
            _connected = true;
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        if (_connected == true) {
          connection.output.add(utf8.encode("0" + "\n"));
          await connection.output.allSent;
          show('Device connected');
        }

        setState(() => _isButtonUnavailable = false);
      }
    }
  }


  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });
    //_logOff();
    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }


  void _logOn() async {
    var date;
    buffer.clear();
    DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH:mm:ss.SSS");
    //DateFormat dateFormat = DateFormat("HH:mm:ss.SSS");
    connection.output.add(utf8.encode("1" + "\n"));
    await connection.output.allSent;
    setState(() {
      _deviceState = 1; // device on
      _logState = 1;
    });
    Message mex;
    connection.input.listen((data){
      _temp = ascii.decode(data);
      _message += _temp;
      if (_message.contains("\n")) {
        setState((){
          _prova = dateFormat.format(DateTime.now()) + ',' + _message;
          buffer.add(_prova);

        });
        _message = '';
        //print(buffer);
        print(buffer.length);
      }
    }).onDone(() {
      if (isDisconnecting) {
        print('Disconnecting locally!');
        _logOff();
      } else {
        print('Disconnected remotely!');
      }
      if (this.mounted) {
        setState(() {});
      }
    });
  }


  // Method to send message,
  // for turning the Bluetooth device off
  void _logOff() async {
    //connection.output.add(utf8.encode("0" + "\r\n"));
    connection.output.add(utf8.encode("0" + "\n"));
    await connection.output.allSent;
    //show('Log Turned Off');
    //_query();
    setState((){
      _deviceState = -1; // device off
      _logState = -1;
      _prova = null;
    });
    print(_prova);
    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }

    while(buffer.isNotEmpty) {
      _splitted = buffer.first.split(",");
      buffer.removeFirst();
      await dbHelper.insert(toMap(_splitted));
    }
    if(buffer.isEmpty) {
      print("finito caricamento");
      show("finito caricamento");
    }
  }


  void _resetMPU() async {
    connection.output.add(utf8.encode("R" + "\n"));
    await connection.output.allSent;
    show('MPU resetted');
  }
/*
  void _query() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach(print);
  }
 */
  // Method to show a Snackbar,
  // taking message as the text
  Future show(String message, {
    Duration duration: const Duration(seconds: 2),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  Map<String, dynamic> toMap(List<dynamic> row) {
    return {
      'time': row[0],
      'latitude': row[1],
      'longitude': row[2],
      's_temp': row[3],
      'b_temp': row[4],
      'b_pressure': row[5],
      'b_altitude': row[6],
      'b_humidity': row[7],
      'accx': row[8],
      'accy': row[9],
      'accz': row[10],
      'gyrox': row[11],
      'gyroy': row[12],
      'gyroz': row[13],
      'angley': row[14],
      'anglex': row[15],
      'anglez': row[16],
    };
  }
}



  //IMESTAMP LATITUDE LONGITUDE S_TEMP TEMP PRESS ALTITUDE HUMIDITY AccX AccY Accz gyroX gyroY gyroZ AccAngleX AccAngleY X Y Z
