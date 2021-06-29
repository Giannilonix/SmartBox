import 'package:finale_app/Message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finale_app/database_helper.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:core';
import 'Message.dart';
import 'package:charts_flutter/flutter.dart' as charts;


class SecondRoute extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}
class _SecondPageState extends State<SecondRoute> {

  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _result = [];
  List<SalesData> data = [];
  Message temp = new Message();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  DateFormat dateFormat2 = DateFormat("yyyy-MM-dd_HH:mm:ss.SSS");
  DateFormat timeFormat = DateFormat("HH:mm:ss.SSS");
  DateTime currentDate = DateTime.now();
  DateTime first, last;
  String start, end;
  double diff;

  @override
  void initState() {
    setState(() {
      currentDate = DateTime.now();
      getChartData(currentDate);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: true,
          //`true` if you want Flutter to automatically add Back Button when needed,
          //or `false` if you want to force your own back button every where
          leading: IconButton(icon:Icon(Icons.arrow_back),
            onPressed:() => Navigator.pop(context, false),
          ),
        title: Text("Graph"),
        backgroundColor: Colors.blueAccent,
        actions:
             <Widget>[
              FlatButton.icon(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: Text(
                  "DatePiker",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                splashColor: Colors.greenAccent,
                onPressed: () => _selectDate(context),
              ),
            ],
            ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Container(
            height: 50,
            color: Colors.blue,
            child: Center(child: Text(
              dateFormat.format(currentDate).toString(),
              style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white),
            ),
            ),
          ),
          Container(
            height: 50,
            color: Colors.blue,
            child: Center(child: Text(
              "$start $end",
              style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white),
            ),
            ),
          ),
          Container(
            height: 300,
            child: //SimpleTimeSeriesChart.withSampleData(),
            SfCartesianChart(
              title: ChartTitle(text: 'Temperature chart'),
                legend: Legend(
                  isVisible: true,
                  position:  LegendPosition.bottom,
                ),
              tooltipBehavior:  TooltipBehavior(enable: true),
              series:<ChartSeries>[
                LineSeries<SalesData,double>(
                  name:'Sond Temp',
                  dataSource: data,
                  xValueMapper: (SalesData sales, _) => sales.time,
                  yValueMapper: (SalesData sales, _) => sales.s_temperature,
                  //dataLabelSettings: DataLabelSettings(isVisible: true),
                  enableTooltip: true
                ),
                LineSeries<SalesData,double>(
                  name:'Bar Temp',
                  dataSource: data,
                  xValueMapper: (SalesData sales, _) => sales.time,
                  yValueMapper: (SalesData sales, _) => sales.bar_temperature,
                  //dataLabelSettings: DataLabelSettings(isVisible: true),
                  enableTooltip: true
                )
              ]
            ),
          ),
          Divider(),
          Container(
            height: 300,
            child: //SimpleTimeSeriesChart.withSampleData(),
            SfCartesianChart(
                title: ChartTitle(text: 'AngleChart'),
                legend: Legend(
                  isVisible: true,
                  position:  LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series:<ChartSeries>[
                  LineSeries<SalesData,double>(
                      name:'Y axe',
                      dataSource: data,
                      xValueMapper: (SalesData sales, _) => sales.time,
                      yValueMapper: (SalesData sales, _) => sales.angleY,
                      //dataLabelSettings: DataLabelSettings(isVisible: true),
                      enableTooltip: true
                  ),
                  LineSeries<SalesData,double>(
                      name:'X axe',
                      dataSource: data,
                      xValueMapper: (SalesData sales, _) => sales.time,
                      yValueMapper: (SalesData sales, _) => sales.angleX,
                      //dataLabelSettings: DataLabelSettings(isVisible: true),
                      enableTooltip: true
                  )
                ]
            ),
          ),
          Divider(),
          Container(
            height: 300,
            child: //SimpleTimeSeriesChart.withSampleData(),
            SfCartesianChart(
                title: ChartTitle(text: 'Altitude chart'),
                legend: Legend(
                  isVisible: true,
                  position:  LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series:<ChartSeries>[
                  LineSeries<SalesData,double>(
                      name:'Altitude (m)',
                      dataSource: data,
                      xValueMapper: (SalesData sales, _) => sales.time,
                      yValueMapper: (SalesData sales, _) => sales.bar_altitude,
                      //dataLabelSettings: DataLabelSettings(isVisible: true),
                      enableTooltip: true
                  ),
                ]
            ),
          ),
          Divider(),
          Container(
            height: 300,
            child: //SimpleTimeSeriesChart.withSampleData(),
            SfCartesianChart(
                title: ChartTitle(text: 'Pressure chart'),
                legend: Legend(
                  isVisible: true,
                  position:  LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series:<ChartSeries>[
                  LineSeries<SalesData,double>(
                      name:'Pressure (hPa)',
                      dataSource: data,
                      xValueMapper: (SalesData sales, _) => sales.time,
                      yValueMapper: (SalesData sales, _) => sales.bar_pressure,
                      //dataLabelSettings: DataLabelSettings(isVisible: true),
                      enableTooltip: true
                  ),
                ]
            ),
          ),
          // ignore: deprecated_member_use
          Divider(),
          ElevatedButton(
            child: Text('Delete daily log'),
            onPressed:() { deletedailylogs();
            },
          ),
          Divider(),
        ],
      )
    );
  }

  void deletedailylogs()async{
    await dbHelper.deleteDailyLog(dateFormat.format(currentDate));
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2021),
        lastDate: DateTime.now());
    if (pickedDate != null && pickedDate != currentDate)
      setState(() {
        currentDate = pickedDate;
      });
    getChartData(currentDate);
  }

//Future<List<SalesData>>
void  getChartData(DateTime inizio) async{
    DateTime moment;
    _result = (await dbHelper.querylog(dateFormat.format(inizio)));
     // _result.forEach((element) => print(element));
    data.clear();
    //int i = _result.length;
    setState(() {
      if(_result.isNotEmpty){
        first = dateFormat2.parse(_result.first['time']);
        last = dateFormat2.parse(_result.last['time']);
        diff =last.difference(first).inMilliseconds.toDouble();
        start = timeFormat.format(first);
        end = timeFormat.format(last);
      }
      else{
        start = "No Data in this date";
        end = "";
      }
    });
    double i = 0;
    _result.forEach((element) {
    setState(() {
          //moment = dateFormat2.parse(element['time']);
          data.add(new SalesData(i++, element['s_temp'],element['b_temp'],element['b_pressure'],element['b_altitude'],element['b_humidity'],element['accx'],element['accy'],element['accz'],element['gyrox'],element['gyroy'],element['gyroz'],element['angley'],element['anglex'],element['anglez']));
        });
      });
  }
}

class SalesData {
  SalesData(this.time, this.s_temperature, this.bar_temperature, this.bar_pressure, this.bar_altitude, this.bar_humidity, this.accX, this.accY, this.accZ, this.gyroX, this.gyroY, this.gyroZ, this.angleY, this.angleX, this.angleZ);

  final double time;
  final double s_temperature;
  final double bar_temperature;
  final double bar_pressure;
  final double bar_altitude;
  final double bar_humidity;
  final double accX;
  final double accY;
  final double accZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final int angleY;
  final int angleX;
  final int angleZ;
}