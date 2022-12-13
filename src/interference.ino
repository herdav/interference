// INTERFERENCE
// Created 2018 & 2023 by David Herren
// https://davidherren.ch
// https://github.com/herdav/interference
// Licensed under the MIT License.
// --------------------------------------

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

int maximumRange = 200;
int minimumRange = 2;
long dist_a, dist_b;
long dura_a, dura_b;

const int def_max_heigh = A0;    // define max heigh
const int def_perspective = A1;  // perspective
const int pot_A2 = A2;           // potentiometer 3
const int pot_A3 = A3;           // potentiometer 4

int val_def_perspective;         // data_c
int val_def_max_heigh;           
int val_pot_A2;                  // data_e
int val_pot_A3;                  // data_f

bool val_on;                     // data_g
bool val_run;                    // data_h

int val_fan_a, val_fan_b;

int max_top;                     // data_d

int data_a, data_b;

String data;

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
  delay(50);
}

void control() {
  val_def_max_heigh = analogRead(def_max_heigh);
  if (val_def_max_heigh > 0) {
    max_top = map(val_def_max_heigh, 0, 1023, 0, 200);
  }

  val_def_perspective = analogRead(def_perspective);

  //val_pot_A2 = analogRead(pot_A2);
  val_pot_A3 = analogRead(pot_A3);

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
    data_a = dist_a;
  }
  if (data_a <= max_top && val_def_max_heigh > 0) {
    val_fan_a = map(data_a, 0, max_top, 255, 220);
  }
  if (data_a > max_top || val_def_max_heigh == 0) {
    val_fan_a = 0;
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
    data_b = dist_b;
  }
  if (data_b <= max_top && val_def_max_heigh > 0) {
    val_fan_b = map(data_b, 0, max_top, 255, 220);
  }
  if (data_b > max_top || val_def_max_heigh == 0) {
    val_fan_b = 0;
  }
}

void actors() {
  if (val_run == true) {
    analogWrite(FAN_A, val_fan_a);
    analogWrite(FAN_B, val_fan_b);
  } else {
    analogWrite(FAN_A, 0);
    analogWrite(FAN_B, 0);
  }
}

void stream() {
  data = normalizeData(data_a, data_b, val_def_perspective, max_top, val_pot_A2, val_pot_A3, val_on, val_run);
  Serial.println(data);
}

String normalizeData(int a, int b, int c, int d, int e, int f, bool g, bool h) {
  String A = String(a);
  String B = String(b);
  String C = String(c);
  String D = String(d);
  String E = String(e);
  String F = String(f);
  String G = String(g);
  String H = String(h);
  String ret = String('a') + A + String('b') + B + String('c') + C + String('d') + D + String('e') + E + String('f') + F + String('g') + G + String('h') + H + String('#');
  return ret;
}
