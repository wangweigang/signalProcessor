
/*
 control a step motor
 20180225 by Weigang
 */

#include <Stepper.h>

// motor parameter
const int stepsPerRevolution = 180;  // change this to fit the number of steps per revolution
int btnClock, btnClockCntr;
int btnClockWasDown, btnClockCntrWasDown;
int stepDeg, stepNum;
float angleStride, angleMax, angleMin, angleCurrent, stepDegAcc;
 

// initialize the stepper library on pins 8 through 11:
Stepper myStepperNE(stepsPerRevolution, 8, 10, 9, 11);

void setup() {

  // set the speed at 60 rpm:
  myStepperNE.setSpeed(60);
  angleMax     =  180;
  angleMin     = -180;
  angleCurrent = 0;
  angleStride  = 5.625/64;  // [deg] for Motor 28BYJ-48
  stepDeg      = 5;
  stepNum      = stepDeg / angleStride;
  stepDegAcc   = 0;
  pinMode(53, INPUT);   // clockwise
  pinMode(51, INPUT);   // back to 0
  pinMode(49, INPUT);   // anticlockwise
  
 
  // initialize the serial port:
  Serial.begin(115200);
  Serial.print("Let's get ready to rumble !");   
}

void loop() {

  btnClock     = digitalRead(53);
  btnClockCntr = digitalRead(54);
  
  if (btnClock = LOW && btnClockWasDown == 0)
  {
    if (stepDegAcc < angleMax)
    {
      myStepperNE.step(stepNum); 
      Serial.print("                Turn clockwise ");
      Serial.print(stepDegAcc);
      Serial.println(" deg");
      stepDegAcc++;
    }
  }
  else if (btnClockCntr = LOW && btnClockCntrWasDown == 0)
  {
    if (stepDegAcc > angleMin)
    {
      myStepperNE.step(-stepNum);
      Serial.print("                Turn counterclockwise ");
      Serial.print(stepDegAcc);
      Serial.println(" deg");
      stepDegAcc--;
    }
  } 
  else
  {
    Serial.println("No moving");
  }


 
 
delay(10);
}

