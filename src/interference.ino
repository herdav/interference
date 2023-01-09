// INTERFERENCE
// Created 2018 & 2023 by David Herren
// https://davidherren.ch
// https://github.com/herdav/interference
// Licensed under the MIT License.
// --------------------------------------

#include <Filter.h> // megunolink.com

#define ECHO_A 8
#define TRIG_A 9
#define ECHO_B 10
#define TRIG_B 11
#define FAN_B 5
#define FAN_A 3
#define ON 4
#define RUN 7
#define LED_ON 2
#define LED_RUN 12

long filterWeight = 100; // 100%
ExponentialFilter<long> ADCFilter(filterWeight, 0); // (weight, initial value)
bool filterADC = true;
bool filterSpike = true;

const int def_max_top = A0;       // potentiometer 0 -> define max top for stop motors
const int def_perspective = A2;   // potentiometer 3 -> define perspective for graphic
const int def_power = A1;         // potentiometer 1 -> define power motors
const int def_runtime = A3;       // potentiometer 2 -> define run time_current

int maximumRange = 200;
int minimumRange = 2;             // 2
float dist_a, dist_b;
float dura_a, dura_b;
int data_dist_a;                  // data_a
int data_dist_b;                  // data_b

int val_fan_a, val_fan_b;
int max_top;                      // data_d
int val_def_max_top;

int val_def_perspective;          // data_c
int val_def_power;                
int val_power;                    // data_e
int val_def_runtime;             
bool val_on;                      // data_h
bool val_on_safed;
bool val_run;                     // data_i
long val_time_run;                // data_f
long time_run_max = 300000;
long val_time_pause;
long val_time_pause_max = 300000;
bool time_run = true;             // data j
long time_current;
long time_safed = 0;
long time_left;                   // data_g -> time_current until toggle run or pause
bool toggled_on_run = false;

String data; // (data_dist_a, data_dist_b, val_def_perspective, max_top, val_power, val_time_run, val_on, val_run)

class spikeFilter {
  private:
  float setMax, dataOut, dataBefore, deltaData;
  int cntBefore;
  int cntBeforeSet = 2;
  int cntPause;
  int cntPauseSet = 6;
  bool pause = false;  
    
  public:
  spikeFilter(float setMax) {
    this->setMax = setMax;
  }
  float getData() {
    return dataOut;
  }
  
  void filter(float dataIn) {
    deltaData = abs(dataIn - dataBefore);    
    if (deltaData > setMax && cntBefore <= cntBeforeSet && !pause) {      
      dataOut = dataBefore;
      cntBefore++;
      //Serial.print(">>");
    } else {
      dataOut = dataIn;
      dataBefore = dataIn;        
    }
    if (cntBefore == cntBeforeSet) {
      cntPause++;
      pause = true;
    }
    if (cntPause == cntBeforeSet) {
      pause = false;
      cntPause = 0;
      cntBefore = 0;      
    }               
  }      
};

float setMax = 10;
spikeFilter spikeFilterA = spikeFilter(setMax);
spikeFilter spikeFilterB = spikeFilter(setMax);

void setup() {
  pinMode(TRIG_A, OUTPUT);
  pinMode(ECHO_A, INPUT);
  pinMode(TRIG_B, OUTPUT);
  pinMode(ECHO_B, INPUT);
  pinMode(ON, INPUT);
  pinMode(RUN, INPUT);
  pinMode(LED_ON, OUTPUT);
  pinMode(LED_RUN, OUTPUT);

  Serial.begin(9600);
}

void loop() {
  sensors();
  actors();
  control();
  stream();
  delay(50); // 50
}

void control() {
  { // max top
    val_def_max_top = analogRead(def_max_top);
    if (val_def_max_top > 0) {
      max_top = map(val_def_max_top, 0, 1023, 0, 200);
    }
  }
  { // value for perspective
    val_def_perspective = analogRead(def_perspective);
  }
  { // timeautomat
    time_current = millis();
    val_def_runtime = analogRead(def_runtime);
    val_time_run = map(val_def_runtime, 0, 1023, 0, time_run_max);

    val_time_pause = val_time_run; // run time_current = pause time_current

    time_left = time_current - time_safed;
    if (val_on == true && val_run == false) {
      time_left = 0;      
    }    

    if ((time_current - time_safed >= val_time_run && time_run == true) || val_on == true && val_run == false) {
      time_run = false;
      time_safed = time_current;
    }
    if ((time_current - time_safed >= val_time_pause && time_run == false) || toggled_on_run == true ) {
      time_run = true;
      time_safed = time_current;
    }
  }
  { // power motors
    val_def_power = analogRead(def_power);
    val_power = map(val_def_power, 0, 1023, 0, 255);
  }
  { // togle switch
    val_on = digitalRead(ON);
    val_run = digitalRead(RUN);

    if (val_on == true) {
      digitalWrite(LED_ON, HIGH);
    } else {
      digitalWrite(LED_ON, LOW);
    }
    if (val_run == true) {
      digitalWrite(LED_RUN, HIGH);
    } else {
      digitalWrite(LED_RUN, LOW);
    }
       
    if (val_on_safed == true && val_run == true) {
      toggled_on_run = true;            
    } else {
      toggled_on_run = false;
    }
    val_on_safed = val_on;
  }
}

void sensors() {
  digitalWrite(TRIG_A, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_A, LOW);
  dura_a = pulseIn(ECHO_A, HIGH);
  dist_a = dura_a / 58.2;

  if (dist_a >= maximumRange) {
    dist_a = maximumRange;
  }
  if (dist_a <= minimumRange) {
    dist_a = 0;
  } else {
    data_dist_a = dist_a;
    if (filterSpike){spikeFilterA.filter(data_dist_a); data_dist_a = spikeFilterA.getData();}
    if (filterADC){ADCFilter.Filter(data_dist_a);}
  }

  digitalWrite(TRIG_B, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_B, LOW);
  dura_b = pulseIn(ECHO_B, HIGH);
  dist_b = dura_b / 58.2;

  if (dist_b >= maximumRange) {
    dist_b = maximumRange;
  }
  if (dist_b <= minimumRange) {
    dist_b = 0;
  } else {
    data_dist_b = dist_b;
    if (filterSpike){spikeFilterB.filter(data_dist_b); data_dist_b = spikeFilterB.getData();}
    if (filterADC){ADCFilter.Filter(data_dist_b);}
  }
}

void actors() {
  { // power motor depends to distance
    if (data_dist_a <= max_top && val_def_max_top > 0) {
      val_fan_a = map(data_dist_a, 0, max_top, 255, val_power);
      }
    if (data_dist_a > max_top || val_def_max_top == 0) {
        val_fan_a = 0;
    }
    if (data_dist_b <= max_top && val_def_max_top > 0) {
        val_fan_b = map(data_dist_b, 0, max_top, 255, val_power);
    }
    if (data_dist_b > max_top || val_def_max_top == 0) {
        val_fan_b = 0;
    }
  }
  /*// on off motor
  {
    if (dist_a < max_top) {
      val_fan_a = val_power;
    } else {
      val_fan_a = 0;
    }
    if (dist_b < max_top) {
      val_fan_b = val_power;
    } else {
      val_fan_b = 0;
    }
  }*/  

  if (val_run == true && (time_run == true || val_time_run <= 0)) {
    analogWrite(FAN_A, val_fan_a);
    analogWrite(FAN_B, val_fan_b);
  } else {
    analogWrite(FAN_A, 0);
    analogWrite(FAN_B, 0);
  }
}

void stream() {    
  data = normalizeData(data_dist_a, data_dist_b, val_def_perspective, max_top, val_power, val_time_run, time_left, val_on, val_run, time_run);
  Serial.println(data);
}

String normalizeData(int a, int b, int c, int d, int e, long f, long g, bool h, bool i, bool j) {
  String A = String(a);
  String B = String(b);
  String C = String(c);
  String D = String(d);
  String E = String(e);
  String F = String(f);
  String G = String(g);
  String H = String(h);
  String I = String(i);
  String J = String(j);
  String ret = String('a') + A + String('b') + B + String('c') + C + String('d') + D + String('e') + E + String('f') + F + String('g') + G + String('h') + H + String('i') + I + String('j') + J + String('#');
  return ret;
}
