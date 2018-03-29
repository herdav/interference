// ORGAN
// Created 2018 by David Herren
// https://github.com/herdav/interference
// Licensed under the MIT License.
// -------------------------------

import  processing.serial.*;
import  cc.arduino.*;

Arduino arduino;
Serial  myPort;
String  portStream;
boolean serial;
int     posB, posC, posEnd;
float   data_a, data_b, data_c; 
float   store_data_a, store_data_b;
float   diff_a, diff_b;
float[] int_data_a = new float[6];
float[] int_data_b = new float[6];
float   int_a, int_b;
int     int_cyc;
int     time, cycle;
String  data;
float   val_data_ab;
float   y_ab, y_k, m;
float   int_y_ab, int_y_k;
float   k = 250.0;

void setup() {
  myPort = new Serial(this, "/dev/ttyACM0", 9600);
  myPort.bufferUntil('\n');
  size(1280, 768);
  //frameRate(120);
  //fullScreen();
}

void draw() {
  background(0);
  stream();
  regulate();
  perspect();
  projection();
  test();
}

void serialEvent(Serial myPort) {
  portStream = myPort.readString();
}

void stream() {
  posB = portStream.indexOf('b');
  posC = portStream.indexOf('c');
  posEnd = portStream.indexOf('#');
  data_a = float(portStream.substring(1, portStream.indexOf('b')));
  data_b = float(portStream.substring(posB + 1, posC));
  data_c = float(portStream.substring(posC + 1, posEnd));
  data_a = map(data_a, 0, 200, 0, height);
  data_b = map(data_b, 0, 200, 0, height);
  data_c = map(data_c, 0, 1023, 0, height);

  cycle = millis() - time;
  time  = millis();
  println(cycle+"ms");
}

void perspect() {
  k = data_c;
  m = k / height;
  y_ab = (data_a + data_b)/2;
  y_k = y_ab - m * y_ab; 
  int_y_ab = (int_a + int_b)/2;
  int_y_k = int_y_ab - m * int_y_ab;  
  //println(m, y_k);
}

void regulate() {
  /*if (data_a > store_data_a) {
   diff_a = data_a/store_data_a;
   } else {
   diff_a = store_data_a/data_a;
   }
   if (data_b > store_data_b) {
   diff_b = data_b/store_data_b;
   } else {
   diff_b = store_data_b/data_b;
   }
   store_data_a = data_a;
   store_data_b = data_b;
   //println(diff_a, diff_b);*/

  int_cyc++;
  if (int_cyc == int_data_a.length) {
    int_cyc = 0;
  }
  int_data_a[int_cyc] = data_a;
  int_data_b[int_cyc] = data_b;

  for (int i = 0; i < int_data_a.length; i++) {
    int_a += int_data_a[i];
    int_b += int_data_b[i];
  }
  int_a = int_a/(int_data_a.length+1);
  int_b = int_b/(int_data_b.length+1);
  //println(int_a, int_b);
}

void projection() {
  strokeWeight(12);
  stroke(255);
  line(0, height-int_a, width/2, height-int_y_k);
  line(width/2, height-int_y_k, width, height-int_b);
}

void test() {
  if (keyCode == UP) {
    strokeWeight(1);
    stroke(0, 255, 0);
    line(0, height-data_a, width/2, height-y_k);
    line(width/2, height-y_k, width, height-data_b);

    fill(0, 255, 0);
    noStroke();
    ellipse(10, height-data_a, 20, 20);
    ellipse(width-10, height-data_b, 20, 20);

    stroke(255);
    strokeWeight(1);
    line(width/2, 0, width/2, height);
    line(0, 0, width/2, k);
    line(width/2, k, width, 0);
  }
}
