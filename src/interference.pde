// INTERFERENCE
// Created 2018 & 2023 by David Herren
// https://davidherren.ch
// https://github.com/herdav/interference
// Licensed under the MIT License.
// --------------------------------------

import  processing.serial.*;
import  cc.arduino.*;

Arduino arduino;
Serial  myPort;

String  portStream;
int     posB, posC, posD, posE, posF, posG, posH, posEnd;
int     maximumRange = 200;
int     minimumRange = 0;
int     store = 20;
int     rand = 0; // 250
int     line = 12;
float   data_a, data_b, data_c, data_d, data_e, data_f, data_g, data_h;
float   store_data_a, store_data_b;
float   diff_a, diff_b;
float[] int_data_a = new float[store];
float[] int_data_b = new float[store];
float   int_a, int_b;
float   val_data_ab;
String  data;
int     int_cyc;
int     time, cycle;
float   y_ab, y_k, m, int_y_ab, int_y_k, k;
boolean on;
boolean run;

void setup() {
  //myPort = new Serial(this, "/dev/ttyACM0", 9600); // Port in Raspbian
  myPort = new Serial(this, "COM6", 9600);           // Port in Windows
  myPort.bufferUntil('\n');
  surface.setResizable(true);
  //fullScreen();
  size(1920, 1080);
  frameRate(120);
  delay(500);
}

void draw() {
  background(0);
  if (myPort.available() > 0 && portStream.charAt(0) == 'a') {
    stream();
  }
  regulate();
  perspect();
  projection();
  control();
}

void serialEvent(Serial myPort) {
  portStream = myPort.readString();
}

void stream() {
  posB = portStream.indexOf('b');
  posC = portStream.indexOf('c');
  posD = portStream.indexOf('d');
  posE = portStream.indexOf('e');
  posF = portStream.indexOf('f');
  posG = portStream.indexOf('g');
  posH = portStream.indexOf('h');
  posEnd = portStream.indexOf('#');
  data_a = float(portStream.substring(1, posB));          // sensor A
  data_b = float(portStream.substring(posB + 1, posC));   // sensor B
  data_c = float(portStream.substring(posC + 1, posD));   // perspective
  data_d = float(portStream.substring(posD + 1, posE));   // 
  data_e = float(portStream.substring(posE + 1, posF));   // 
  data_f = float(portStream.substring(posF + 1, posG));   // 
  data_g = float(portStream.substring(posG + 1, posH));   // 
  data_h = float(portStream.substring(posH + 1, posEnd)); //

  println(cycle + "ms", round(frameRate) + "fps", "a:" + round(data_a), "b:" + round(data_b), "c:" + round(data_c), "d:" + round(data_d), "e:" + round(data_e), "f:" + round(data_f), "g:" + round(data_g), "h:" + round(data_h));

  if (Float.isNaN(data_a)) {
    System.err.println("data_a : NaN");
    data_a = minimumRange;
  } else {
    data_a = map(data_a, minimumRange, maximumRange, 0, height);
  }
  if (Float.isNaN(data_b)) {
    System.err.println("data_b : NaN");
    data_b = minimumRange;
  } else {
    data_b = map(data_b, minimumRange, maximumRange, 0, height);
  }
  if (Float.isNaN(data_c)) {
    System.err.println("data_c : NaN");
    data_c = minimumRange;
  } else {
    data_c = map(data_c, 0, 1023, 0, height);
  }
}

void regulate() {
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
  int_a = int_a / (int_data_a.length + 1);
  int_b = int_b / (int_data_b.length + 1);
  //println(int_a, int_b);
}

void perspect() {
  k = data_c;
  m = k / height;
  y_ab = (data_a + data_b) / 2;
  y_k = y_ab - m * y_ab; 
  int_y_ab = (int_a + int_b) / 2;
  int_y_k = int_y_ab - m * int_y_ab;  
  //println(m, y_k);
}

void projection() {
  noFill();
  strokeWeight(line);
  stroke(255);
  beginShape();
  vertex(rand, height - int_a);
  vertex(width / 2, height - int_y_k);
  vertex(width - rand, height - int_b);
  endShape();
  fill(0);
  noStroke();
  rect(0, 0, rand + line / 2, height);
  rect(width - rand - line / 2, 0, width, height);
}

void control() {
  if (int(data_g) > 0) {
    on = true;
  } else {
    on = false;
  }
  if (int(data_h) > 0) {
    run = true;
  } else {
    run = false;
  }

  if (keyCode == UP || (on && !run)) {
    stroke(255, 255, 0);
    strokeWeight(1);
    line(rand, height - data_a, width / 2, height - y_k);
    line(width / 2, height - y_k, width - rand, height - data_b);
    line(rand, 0, rand, height);
    line(rand, 0, width - rand, 0);
    line(width - rand, 0, width - rand, height);
    line(rand, height - 1, width - rand, height - 1);

    fill(255, 255, 0);
    noStroke();
    ellipse(10 + rand, height - data_a, 20, 20);
    ellipse(width - 10 - rand, height - data_b, 20, 20);

    stroke(255);
    strokeWeight(1);
    line(width / 2, 0, width / 2, height);
    line(rand, 0, width / 2, k);
    line(width / 2, k, width - rand, 0);
  }
  cycle = millis() - time;
  time  = millis();
}
