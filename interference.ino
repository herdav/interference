// ORGAN
// Created 2018 by David Herren
// https://github.com/herdav/interference
// Licensed under the MIT License.
// -------------------------------

#define ECHO_A 8
#define TRIG_A 9
#define ECHO_B 10
#define TRIG_B 11

int maximumRange = 150;
int minimumRange = 2;
long dist_a, dist_b;
long dura_a, dura_b;

const int pot = A0;
int val_pot;

const int pers = A5;
int val_pers;

int fan_pin_a = 3;
int fan_pin_b = 5;
int fan_a, fan_b;
int max_top = 120;
int data_a, data_b;

String data;

void setup() {
  pinMode(TRIG_A, OUTPUT);
  pinMode(ECHO_A, INPUT);
  pinMode(TRIG_B, OUTPUT);
  pinMode(ECHO_B, INPUT);
  Serial.begin(9600);
}

void loop() {
  val_pot = analogRead(pot);
  if (val_pot > 0) {
    max_top = map(val_pot, 0, 1023, 0, 200);
  }
  val_pers = analogRead(pers);
  
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
  }
  else {
    data_a = dist_a;
  }
  if (data_a <= max_top && val_pot > 0) {
    fan_a = map(data_a, 0, max_top, 255, 220);
  }
  if (data_a > max_top || val_pot == 0) {
    fan_a = 0;
  }
  analogWrite(fan_pin_a, fan_a);

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
  }
  else {
    data_b = dist_b;
  }
  if (data_b <= max_top  && val_pot > 0) {
    fan_b = map(data_b, 0, max_top, 255, 220);
  }
  if (data_b > max_top || val_pot == 0) {
    fan_b = 0;
  }
  analogWrite(fan_pin_b, fan_b);

  delay(50);
  data = normalizeData(data_a, data_b, val_pers);
  Serial.println(data);
}

String normalizeData(int a, int b, int c) {
  String A = String(a);
  String B = String(b);
  String C = String(c);
  String ret = String('a') + A + String('b') + B + String('c') + C + String('#');
  return ret;
}
