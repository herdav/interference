// INTERFERENCE
// Created 2018 & 2023 by David Herren
// https://davidherren.ch
// https://github.com/herdav/interference
// Licensed under the MIT License.
// --------------------------------------

import  processing.serial.*;
import  cc.arduino.*;
import  signal.library.*;

Serial  myPort;
Arduino arduino;
String  portStream;
int     posB, posC, posD, posE, posF, posG, posH, posI, posJ, posEnd;
int     maximumRange = 200; // same as in arduino sketch for data_a and data_b

SignalFilter filter_data_a, filter_data_b; // signal filter
float   minCutoff = 0.01;     // decrease this to get rid of slow speed jitter (0.05) 0.005
float   beta      = 10.0;     // increase this to get rid of high speed lag (4) 10
boolean signalFilter = true;  // set for filtering signal

float   data_a, data_b, data_c, data_d, data_e, data_f, data_g, data_h, data_i, data_j;
int     store = 10; // for moving average
float[] int_data_a = new float[store];
float[] int_data_b = new float[store];
float   int_a, int_b;
int     int_cyc;

int     time, cycle;

int     rand = 0; // 250
int     line = 12;
int     line_bottom = 55;
float   y_ab, y_k, m, int_y_ab, int_y_k, k, int_x; // for graphic callculation
boolean on, run;

void setup() {
  //myPort = new Serial(this, "/dev/ttyACM0", 9600); // Port in Raspbian
  myPort = new Serial(this, "COM6", 9600);           // Port in Windows
  myPort.bufferUntil('\n');
  surface.setResizable(true);
  if (signalFilter) {
    filter_data_a = new SignalFilter(this);
    filter_data_b = new SignalFilter(this);
  }
  //fullScreen();
  size(1920, 1080);
  frameRate(120);
  delay(2000);
}

void draw() {
  background(0);
  if (myPort.available() > 0 && portStream.charAt(0) == 'a') {stream();}
  regulate();
  perspect();
  projection();
  control();
  delay(20);
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
  posI = portStream.indexOf('i');
  posJ = portStream.indexOf('j');
  posEnd = portStream.indexOf('#');
  data_a = float(portStream.substring(1, posB));               // sensor A
  data_b = float(portStream.substring(posB + 1, posC));        // sensor B
  data_c = float(portStream.substring(posC + 1, posD));        // set perspective
  data_d = float(portStream.substring(posD + 1, posE));        // set max top
  data_e = float(portStream.substring(posE + 1, posF));        // set motor power
  data_f = float(portStream.substring(posF + 1, posG));        // set time run and pause
  data_g = float(portStream.substring(posG + 1, posH));        // time left
  data_h = float(portStream.substring(posH + 1, posI));        // toggle on
  data_i = float(portStream.substring(posI + 1, posJ));        // toggle on
  data_j = float(portStream.substring(posJ + 1, posEnd));      // time run or pause

  println("a:" + data_a, "b:" + data_b, "c:" + round(data_c), "d:" + round(data_d), "e:" + round(data_e), "f:" + round(data_f), "g:" + round(data_g), "h:" + round(data_h), "i:" + round(data_i), "j:" + round(data_j), cycle + "ms", round(frameRate) + "fps");

  { // clean and map data
    if (Float.isNaN(data_a)) {
      System.err.println("data_a : NaN");
      data_a = 0;
    } else {
      if (signalFilter) {data_a = filter_data_a.filterUnitFloat(data_a / 1000) * 1000;}
      data_a = map(data_a, 0, maximumRange, 0, height); // map data
    }
    if (Float.isNaN(data_b)) {
      System.err.println("data_b : NaN");
      data_b = 0;
    } else {
      if (signalFilter) {data_b = filter_data_b.filterUnitFloat(data_b / 1000) * 1000;}
      data_b = map(data_b, 0, maximumRange, 0, height); // map data
    }
    if (Float.isNaN(data_c)) {
      System.err.println("data_c : NaN");
      data_c = 0;
    } else {
      data_c = map(data_c, 0, 1023, 0, height);
    }
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
  int_a = (int_a / (int_data_a.length + 1));
  int_b = (int_b / (int_data_b.length + 1));
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

  if (data_j == 1) {
    beginShape();
    vertex(rand, height - int_a);
    vertex(width / 2, height - int_y_k);
    vertex(width - rand, height - int_b);
    endShape();
  } else if (data_j == 0) {
    int_x = map(data_g, 0, data_f, 0, width / 2);
    line(width / 2, height - line_bottom, width / 2 - int(int_x), height - line_bottom);
    line(width / 2, height - line_bottom, width / 2 + int(int_x), height - line_bottom);
  }

  fill(0);
  noStroke();
  rect(0, 0, rand + line / 2, height);
  rect(width - rand - line / 2, 0, width, height);
}

void control() {
  if (int(data_h) > 0) {
    on = true;
  } else {
    on = false;
  }
  if (int(data_i) > 0) {
    run = true;
  } else {
    run = false;
  }

  if (keyCode == UP || (on && !run)) {
    { // draw help lines
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
    { // show stream data
      // data_dist_a, data_dist_b, val_def_perspective, max_top, val_power, val_time_run, time_left, val_on, val_run, time_run
      fill(255, 255, 255);
      textSize(30);
      text("Sensor A: " + round(data_a) + "/" + height + "px", 40, 120);
      text("Sensor B: " + round(data_b) + "/" + height + "px", 40, 180);
      text("Perspective: " + round(data_c), 40, 240);
      text("Max Top: " + round(data_d) + "/200", 40, 300);
      text("Power: " + round(data_e), 40, 360);
      text("Run Time Set: " + round(data_f / 1000) + "s", 40, 420);
      text("Run Time Left: " + round(data_g / 1000) + "s", 40, 480);
      if (data_j == 1 && data_i == 1) {fill(0,255,0); text("[runs]", 320, 480);}
      else {fill(255,0,0); text("[paused]", 320, 480);}
      fill(255,255,255);
      if (data_h == 1) {text("Toggle: On", 40, 540);}
      else if (data_i == 1) {text("Toggle: Run", 40, 540);}
      text(cycle + "ms " + round(frameRate) + "fps", 40, 600);

      text("a:" + round(data_a) + " b:" + round(data_b) + " c:" + round(data_c) + " d:" + round(data_d) + " e:" + round(data_e) + " f:" + round(data_f) + " g:" + round(data_g) + " h:" + round(data_h) + " i:" + round(data_i) + " j:" + round(data_j), 40, height - 80);
    }
  }
  cycle = millis() - time;
  time  = millis();
}
