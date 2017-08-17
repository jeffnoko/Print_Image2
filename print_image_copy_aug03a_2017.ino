// Joystick.pde 
// -*- mode: C++ -*- 
// 
// Track forward/reverse speed from a joystick 
// 
// Copyright (C) 2016 Mike McCauley 
// $Id: $ 

#include <AccelStepper.h> 
#include <MultiStepper.h>
AccelStepper stepper1(1,2,3);
AccelStepper stepper2(1,10,11);
AccelStepper stepper3(1,6,7);
MultiStepper steppers;

#include <Servo.h> 
#include <Wire.h>

Servo servo1; 
Servo servo2; 
Servo servo3; 

// Define a stepper and the pins it will use 
//AccelStepper stepper; // Defaults to AccelStepper::FULL4WIRE (4 pins) on 2, 3, 
//4, 5 

#define JOYSTICK_PIN1 A14 
#define JOYSTICK_PIN2 A15 
#define MAX_SPEED 2000 
#define INPUT_READ_INTERVAL 100 
unsigned long last_input_time = 0; 
 int voltageS = 13;
 int voltageT = 12;
  int voltageU = 11;
   int voltageV = 10;
   
   long aSegment = 250;
int abuffer = 2000;//750 first run, second run 1000 18 dots a direction
int bbuffer = 2250;// 1000 first run, 1250 second run
//int bStartSegment = 300;
int bSegment = 250;
int bStart = 0;

volatile int sensorX1 = 4; //X limitswitch
volatile int sensorStateX1 = 0;
volatile int sensorY1 = 48;// Y limitswitch
volatile int sensorStateY1 = 0;

int paint;
 int startButton = 24;
  int newButton = 26;
 
uint8_t image[20 * 30];
 
int maxY = 40000 / 4;//     20000  orininal 
int maxX = 30000 / 4;//     30000   

void setup() 
{   
  Serial.begin(9600); 
  
  // Change these to suit your stepper if you want 
  stepper1.setMaxSpeed(0); 
  stepper1.setAcceleration(2000); 
   stepper2.setMaxSpeed(0); 
  stepper2.setAcceleration(2000); 
//  stepper.moveTo(1000000000); 
 pinMode (A13, INPUT);
    pinMode (A12, INPUT);
    pinMode (A11, INPUT);
     pinMode (A10, INPUT);
      pinMode (startButton, INPUT_PULLUP); //Yellow button
       pinMode (newButton, INPUT_PULLUP); //Red button

  servo1.attach(8);//paint
  servo1.write(90);
   servo2.attach(9);//trigger
  servo2.write(165);

   homingXY();
 
}

void tickDrawing() {
  static boolean pixelDrawn = true;
  static int drawIndex = 0;
  
  boolean moving = stepper1.isRunning() || stepper2.isRunning();
  
  if (moving) {
    return;
  }
  
  if (pixelDrawn) {
    // Start next move
    pixelDrawn = false;
    
    int x = drawIndex % 20;
    int y = drawIndex / 20;
    
    stepper2.moveTo(y * (maxY / 30));
    stepper1.moveTo(x * (maxX / 20));
  } else {
    int currentPixel = 0xff - image[drawIndex++];
    sprayOn(currentPixel * 4);
    delay(10);
    sprayOff();
    
    pixelDrawn = true;
  }
}

void loop() {
  static int pixelIndex = 0;
  
  while (Serial.available() > 0) {
    uint8_t pixel = Serial.read();
    image[pixelIndex++] = pixel;
    //Serial.println(pixelIndex);
  }
  
  static boolean starting = true;
  
  if (pixelIndex >= 20 * 30 - 1) {
    if (starting) {
      Serial.println("drawing picture");
      starting = false;
    }
    
    tickDrawing();
  }
  
  stepper1.run();
  stepper2.run();
}
