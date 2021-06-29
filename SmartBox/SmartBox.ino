#include<Wire.h>                //for I2C communication
#include <SoftwareSerial.h>     //for serial communication
#include <Adafruit_BME280.h>    //for GY-BME280 sensor
#include <TinyGPS++.h>          //for GPS Module
#include <OneWire.h>            //for ds18b20 
#include <DallasTemperature.h>  //for ds18b20 
#include <MPU6050_tockn.h>      //for interacting whit MPU6050
#include "BluetoothSerial.h"    //for Bluetooth Serial communication

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif //this is a configuration for ESP32 board where bluetooth is integrated

BluetoothSerial SerialBT; 

Adafruit_BME280 bme;

TinyGPSPlus gps;

MPU6050 mpu6050(Wire);

//blu and green are the LED colors, when the blu led is on it means that we are connected via blluetooth
//when the green LED is on it means that the log was started
#define blu 27      //used to simplify the code while using pinMode and DigitalWrite
#define green 25    //used to simplify the code while using pinMode and DigitalWrite

#define SEALEVELPRESSURE_HPA (1013.25) // 1013.25 is a average value but it depends a lot by the weather conditions

//Declaring some global variable
static const uint32_t Baudrate = 115200;
const int oneWireBus = 14;  //this is the digital pin used to read temperature from probe

OneWire oneWire(oneWireBus);
DallasTemperature sensors(&oneWire);

//Probe data
float s_temperature; 

//MPU data
float accX, accY, accZ;
float gyroX, gyroY, gyroZ;
float accAngleX, accAngleY;
float gyroAngleX,gyroAngleY,gyroAngleZ; 
float angleX,angleY,angleZ;

long timer = 0;

//______BAROMETER________
float bar_temperature;
float bar_pressure;
float bar_altitude;
float bar_humidity;

float initial_pressure;

//______GPS________
float Latitude;         //GPS Latitudine
float Longitude;        //GPS Longitudine

// Handle received and sent messages vie Bluetooth
String message = "";
char incomingChar;


void mpu(){
  
  mpu6050.update();  //this function update MPU registers
  
  //if(millis() - timer > 1000){      
    accX=mpu6050.getAccX();         
    accY=mpu6050.getAccY();
    accZ=mpu6050.getAccZ();
    
    gyroX=mpu6050.getGyroX();
    gyroY=mpu6050.getGyroY();
    gyroZ=mpu6050.getGyroZ();
    
    accAngleX=mpu6050.getAccAngleX();
    accAngleY=mpu6050.getAccAngleY();
    
    gyroAngleX=mpu6050.getGyroAngleX();
    gyroAngleY=mpu6050.getGyroAngleY();
    gyroAngleZ=mpu6050.getGyroAngleZ();
  
    angleX=mpu6050.getAngleX();
    angleY=mpu6050.getAngleY();
    angleZ=mpu6050.getAngleZ();
    
   timer = millis();
  // }              
}
//function that reads temperature data from the temperature probe
void sonda(){
  sensors.requestTemperatures(); 
  s_temperature = sensors.getTempCByIndex(0); 
  }
  
//function that reads barometric data from the barometer
void barometer(){
  bar_temperature=bme.readTemperature(); //(°C)
  bar_pressure=(bme.readPressure() / 100.0F); //(hpa)
  //bar_altitude=bme.readAltitude(SEALEVELPRESSURE_HPA); //this is the altitude from the SEA LEVEL 
  bar_altitude=bme.readAltitude(initial_pressure); //(m) //this is the altitude deviation from the Initial point
  bar_humidity=bme.readHumidity(); //(%)
  }

//function that reads temperature data from the gps
void gps_sensor(){
 while (Serial2.available() > 0){   //ESP32 provides two Serial, so i choose the Serial2 for the GPS
   if (Serial2.available() > 0){
    gps.encode(Serial2.read());
    if (gps.location.isUpdated()){
       Latitude=gps.location.lat();
       Longitude=gps.location.lng();
    }
   }
  }
}

//function that sends data via Bluetooth
void blue(){
  // the following row are used to write in the Serial Bluetooth all the data retrieved from the sensors
  SerialBT.print(String(Latitude,6));
  SerialBT.print(",");
  SerialBT.print(String(Longitude,6));
  SerialBT.print(",");
  SerialBT.print(s_temperature);
  SerialBT.print(",");
  SerialBT.print(bar_temperature);
  SerialBT.print(",");
  SerialBT.print(bar_pressure);
  SerialBT.print(",");
  SerialBT.print(bar_altitude);
  SerialBT.print(",");
  SerialBT.print(bar_humidity);
  SerialBT.print(",");
  SerialBT.print(accX);
  SerialBT.print(",");
  SerialBT.print(accY);
  SerialBT.print(",");
  SerialBT.print(accZ);
  SerialBT.print(",");
  SerialBT.print(gyroX);
  SerialBT.print(",");
  SerialBT.print(gyroY);
  SerialBT.print(",");
  SerialBT.print(gyroZ);
  SerialBT.print(",");
  SerialBT.print(int(angleY)); //roll (or pitch) depends by axis direction
  SerialBT.print(",");
  SerialBT.print(int(angleX)); //pitch (or roll)
  SerialBT.print(",");
  SerialBT.println(int(angleZ)); //yaw

  if (SerialBT.available()){
    char incomingChar = SerialBT.read();
  if (incomingChar != '\n'){       
      message += String(incomingChar);  //queue the incoming char until it is equal to endline
    }
    else{
      message = "";
    }
    
    Serial.write(incomingChar);  
    Serial.print(message);  
  }
   
  // Check received message and control output accordingly
  if (message =="1"){
    digitalWrite(green, HIGH); //switch on the green LED (log is started)
    Serial.println("entra nell if log_on");  
  }
  else if (message =="0"){
    digitalWrite(green, LOW); //switch off the blue LED (log is stopped)
     Serial.println("entra nell if log_off");  
  }
  else if(message =="R"){ //in this case we can calculate the gyro offset (calibration) again
   mpu6050.begin();
   mpu6050.calcGyroOffsets(true, 1000);
   Serial.println("Reset MPU");  
  }
  delay(20);
}

//this function allows to detect when the board is correctly connected with the smartphone
void callback(esp_spp_cb_event_t event, esp_spp_cb_param_t *param){
  if(event == ESP_SPP_SRV_OPEN_EVT){
    Serial.println("Client Connected");
    //SerialBT.println("TIMESTAMP LATITUDE LONGITUDE S_TEMP TEMP PRESS ALTITUDE HUMIDITY AccX AccY Accz gyroX gyroY gyroZ Roll Pitch Yaw");
    digitalWrite(blu, HIGH);
  }
 //when bluetooth connection is closed we switch off all the leds
  if(event == ESP_SPP_CLOSE_EVT ){
    Serial.println("Client disconnected");
    digitalWrite(blu, LOW);
    digitalWrite(green, LOW);
  }
}

//this function prints on serial all the retrieved data, it was very usefull during the development
void setSerial(){
  Serial.print(String(Latitude,6));
  Serial.print(" , ");
  Serial.print(String(Longitude,6));
  Serial.print(" , ");
  Serial.print(s_temperature);
  Serial.print(" , ");
  Serial.print(bar_temperature);
  Serial.print(" , ");
  Serial.print(bar_pressure);
  Serial.print(" , ");
  Serial.print(bar_altitude);
  Serial.print(" , ");
  Serial.print(bar_humidity);
  Serial.print(" | ");
  Serial.print(accX);
  Serial.print(" , ");
  Serial.print(accY);
  Serial.print(" , ");
  Serial.print(accZ);
  Serial.print(" | ");
  Serial.print(gyroX);
  Serial.print(" , ");
  Serial.print(gyroY);
  Serial.print(" , ");
  Serial.print(gyroZ);
  Serial.print(" | ");
  Serial.print(accAngleX);
  Serial.print(" , ");
  Serial.print(accAngleY);
  Serial.print(" | ");
  Serial.print(gyroAngleX);
  Serial.print(" , ");
  Serial.print(gyroAngleY);
  Serial.print(" , ");
  Serial.print(gyroAngleZ);
  Serial.print(" | ");
  Serial.print(int(angleY)); //roll (or pitch) depends by axis direction
  Serial.print(" , ");
  Serial.print(int(angleX)); //pitch (or roll)
  Serial.print(" , ");
  Serial.print(int(angleZ)); //yaw
  Serial.print(" | ");
  Serial.println();
}

//this function run once and it is used to setup the system
void setup() {
  Wire.begin(); 
                                                  
  Serial.begin(Baudrate); //inizialize the first serial
  
  Serial2.begin(Baudrate); //inizialize the second serial (RXPin = 16, TXPin = 17)

  if (!bme.begin(0x76)) {
    Serial.println("Could not find a valid BME280 sensor, check wiring!");
    while (1);
  }
  

  
  sensors.begin();
  
  mpu6050.begin();
  
  mpu6050.calcGyroOffsets(true, 1000); //we store the initial Gyro offset to calibrate the IMU
  
  Serial.println();
  Serial.println("TIMESTAMP LATITUDE LONGITUDE S_TEMP TEMP PRESS ALTITUDE HUMIDITY AccX AccY Accz gyroX gyroY gyroZ Roll Pitch Yaw");

  if(!SerialBT.begin("ESP32test")){
    Serial.println("An error occurred initializing Bluetooth");
  }else{
    Serial.println("The device started, now you can pair it with bluetooth!");
  }

  SerialBT.register_callback(callback);
  
  pinMode(blu,OUTPUT);     //setting the digital pin blu in OUTPUT
  pinMode(green,OUTPUT);   //setting the digital pin green in OUTPUT
  digitalWrite(blu, LOW);  //setting the digital pin blu at LOW (0V)   [LED is off]
  digitalWrite(green, LOW);//setting the digital pin green at LOW (0V) [LED is off]

  initial_pressure=(bme.readPressure() / 100.0F); //this is the offset that allows to calculate altitude deviation
}

void loop() {
  
  gps_sensor();
  
  barometer();
  
  sonda();
  
  mpu();
  
  blue();
  
  delay(200);
 
  //setSerial();
}
