import 'package:flutter/widgets.dart';

class Message {
  @required
  final String time;
  final String latitude;
  final String longitude;
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

  Message(
      {this.time, this.latitude, this.longitude, this.s_temperature, this.bar_temperature, this.bar_pressure, this.bar_altitude, this.bar_humidity, this.accX, this.accY, this.accZ, this.gyroX, this.gyroY, this.gyroZ, this.angleY, this.angleX, this.angleZ});

  Map<String, dynamic> toMap(List<dynamic> splitted) {
    return {
      'time': splitted[0],
      'latitude': splitted[1],
      'longitude': splitted[2],
      's_temp': splitted[3],
      'b_temp': splitted[4],
      'b_pressure': splitted[5],
      'b_altitude': splitted[6],
      'b_humidity': splitted[7],
      'accx': splitted[8],
      'accy': splitted[9],
      'accz': splitted[10],
      'gyrox': splitted[11],
      'gyroy': splitted[12],
      'gyroz': splitted[13],
      'angley': splitted[14],
      'anglex': splitted[15],
      'anglez': splitted[16],

    };
  }

  Message.fromMapObject(Map<String, dynamic> messageMap)
      : time= messageMap['time'],
        latitude= messageMap['latitude'],
        longitude= messageMap['longitude'],
        s_temperature= messageMap['s_temp'],
        bar_temperature= messageMap['b_temp'],
        bar_pressure= messageMap['b_press'],
        bar_altitude= messageMap['b_altitude'],
        bar_humidity= messageMap['b_humidity'],
        accX= messageMap['accx'],
        accY= messageMap['accy'],
        accZ= messageMap['accz'],
        gyroX= messageMap['gyrox'],
        gyroY= messageMap['gyrox'],
        gyroZ= messageMap['gyrox'],
        angleY= messageMap['angley'],
        angleX= messageMap['anglex'],
        angleZ= messageMap['anglez'];


  @override
  String toString() {
    return 'Message{time: $time,latitude: $latitude,longitude: $longitude, s_temp: $s_temperature,b_temp: $bar_temperature,b_pressure: $bar_pressure,b_altitude: $bar_altitude, b_humidity $bar_humidity,accx: $accX,accy: $accY,accz: $accZ, gyrox: $gyroX,gyroy: $gyroY,gyroz: $gyroZ,angley: $angleY,angleX: $angleX,anglez: $angleZ}';;
    'Message{time: $time,latitude,longitude, s_temp,b_temp,b_pressure,b_altitude,b_humidity,accx,accy,accz,gyrox,gyroy,gyroz,angley,anglex,anglez}';
    //Message{time: $id, title: $title, message: $message}';
  }
}