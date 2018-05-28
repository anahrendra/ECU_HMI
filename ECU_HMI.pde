// Nama file     : ECU_HMI.pde
// Editor        : TA1718.01.009
// Last update   : 23 April 2017
// Board type    : Arduino Mega 2560
// Port number   : /dev/cu.usbmodem1411
// Baud rate     : 9600

import grafica.*;
import processing.serial.*;

PImage logo, logoITB, logoSTEI, logoABET, logoECU, name, gauge;
PShape rectGauge; 
PShape bgBox;
PShape bgBoxPID;
PShape fuelGauge;
GPlot plot1,plot2;
PrintWriter output;

int cx, cy;
float secondsRadius;
float minutesRadius;
float hoursRadius;
float clockDiameter;


int windowX = 1100;
int windowY = 715;
int y;
int timeX;
int timeY = 190;
int i,k;
int j = 0;

int gaugeSizeX = 150;
int gaugeSizeY = 20;

int matLocX;
int matLocY;

int chtLocX;
int chtLocY;

int pressureLocX;
int pressureLocY;

int afrLocX;
int afrLocY;

int rpmLocX;
int rpmLocY;

int tpsLocX;
int tpsLocY;

int pidLocX;
int pidLocY;

int rectX = 1010;
int rectY = 665;
int rectSizeX = 80;
int rectSizeY = 30;

boolean rectOver = false;
boolean logState = false;
boolean textOver = false;
boolean inputState = false;

float time,rpm;
float f_MAT, f_CHT, f_Lambda, f_MAP, voltPress, f_TPS, ccm, totalCons, printEngine;

float matLow = -40;
float matHigh = 60;
float chtLow = 20;
float chtHigh = 250;
float mapLow = 0;
float mapHigh = 1;
float lambdaLow = 7.35;
float lambdaHigh = 22.39;
float tpsLow = 0;
float tpsHigh = 100;

float rangeMAT;
float rangeCHT;
float rangeMAP;
float rangeLambda;
float rangeTPS;

int s; 
int m; 
int h; 
int dd; 
int mm; 
int yy; 
int h1,h2,m1,m2,s1,s2;
int idleTime;
int idleM,idleS;

GPointsArray points = new GPointsArray();

Serial myPort;

String title = "";

void setup(){
    frameRate(60);
    size(1100, 715);
    pixelDensity(2);
    smooth();

    // Data logging
    
    rangeMAT = matHigh - matLow;
    rangeCHT = chtHigh - chtLow;
    rangeMAP = mapHigh - mapLow;
    rangeLambda = lambdaHigh - lambdaLow;
    rangeTPS = tpsHigh - tpsLow;

    int radius = 40;
    secondsRadius = radius * 0.72;
    minutesRadius = radius * 0.60;
    hoursRadius = radius * 0.50;
    clockDiameter = radius * 1.8;
    cx = 43;
    cy = 200;

    printArray(Serial.list());
    myPort = new Serial(this,Serial.list()[2], 115200);
    myPort.bufferUntil('\n');
    logo = loadImage("aeroterrascan-logo.png");
    logoITB = loadImage("itb.png");
    logoSTEI = loadImage("stei-itb.png");
    logoABET = loadImage("logo_abet.png");
    logoECU = loadImage("Logo.png");
    name = loadImage("ATSname.png");
    
    

    timeX = 80;

    rectGauge = createShape(RECT, 0, 0, gaugeSizeX, gaugeSizeY);
    rectGauge.setFill(false);
    rectGauge.setStroke(true);

    fuelGauge = createShape(RECT, 0, 0, gaugeSizeY+30, gaugeSizeX-35);
    fuelGauge.setFill(false);
    fuelGauge.setStroke(true);

    bgBox = createShape(RECT, 0, 0, 1000, 455);
    bgBox.setFill(color(240, 230, 210));
    bgBox.setStroke(false);

    bgBoxPID = createShape(RECT, 0, 0, 100, 455);
    bgBoxPID.setFill(color(115, 195, 230));
    bgBoxPID.setStroke(false);

    // Gauges Location
    matLocX = 300;
    matLocY = 180;

    chtLocX = matLocX + 200;
    chtLocY=matLocY;

    pressureLocX = matLocX + 400;
    pressureLocY = matLocY;  

    afrLocX = 20;
    afrLocY = matLocY+130;  

    rpmLocX = afrLocX;
    rpmLocY = afrLocY + 260;

    tpsLocX = afrLocX;
    tpsLocY = afrLocY + 130;

    pidLocX = 1005;
    pidLocY = 265;

    //Setting awal plot AFR
    plot1 = new GPlot(this);
    plot1.setPos(afrLocX+180, afrLocY-80);
    plot1.setMar(60, 70, 40, 70);
    plot1.setDim(700, 150);
    plot1.setAxesOffset(4);
    plot1.setTicksLength(4);

    plot1.setPoints(points);
    plot1.setTitleText("Air-to-fuel Ratio");
    plot1.getYAxis().setAxisLabelText("g/g");
    plot1.getXAxis().setAxisLabelText("Time (miliseconds)");
    plot1.setHorizontalAxesTicksSeparation(1000);

    // Activate the panning (only for the first plot)
    plot1.activatePanning();

    //Setting awal plot engine RPM
    plot2 = new GPlot(this);
    plot2.setPos(rpmLocX+180, rpmLocY-110);
    plot2.setMar(60, 70, 40, 70);
    plot2.setDim(700, 150);
    plot2.setAxesOffset(4);
    plot2.setTicksLength(4);
 
    // Set the points, the title and the axis labels
    plot2.setTitleText("Engine RPM");
    plot2.setHorizontalAxesTicksSeparation(1000);
    plot2.getYAxis().setAxisLabelText("RPM");
    plot2.getXAxis().setAxisLabelText("Time (miliseconds)");

    // Activate the panning (only for the first plot)
    plot2.activatePanning();
}

void draw(){
    update(mouseX,mouseY);
    s = second();  // Values from 0 - 59
    m = minute();  // Values from 0 - 59
    h = hour();    // Values from 0 - 23
    dd = day();
    mm = month();
    yy = year();
        
    //Display background and logo
    background( 253 , 246 , 227 );
    image(logo, 0, 0);
    image(logoITB, 950, 5);
    image(logoSTEI, 930, 150);
    image(logoABET, 1015, 160);
    image(logoECU,280,5);
    
    //textSize(50);fill(10, 100, 149); text("Engine Control Unit", 300, 50);
    textSize(32);fill(10, 100, 149); text("Monitoring HMI ", 550, 70);

    displayTime();
    clock();
    engineIndicatorLight();
    matGauge();
    chtGauge();
    pressure();
    afrGauge();
    tpsGauge();
    rpmGauge();
    fuelCons();

    // Draw the first plot
    plot1.addPoint(time,f_Lambda);
    if(time>10000){
        plot1.removePoint(0);
    }
    plot1.beginDraw();
    plot1.drawBox();
    plot1.drawXAxis();
    plot1.drawYAxis();
    plot1.drawTitle();
    plot1.setPointColor(color(150, 9, 9));
    plot1.setLineColor(color(150, 9, 9));
    plot1.drawLines();
    plot1.drawGridLines(GPlot.VERTICAL);
    plot1.drawGridLines(GPlot.HORIZONTAL);
    plot1.endDraw();

    plot2.addPoint(time,rpm);
    if(time>10000){
        plot2.removePoint(0);
    }
    plot2.beginDraw();
    plot2.drawBox();
    plot2.drawXAxis();
    plot2.drawYAxis();
    plot2.drawTitle();
    plot2.setPointColor(color(23, 157, 162));
    plot2.setLineColor(color(23, 157, 162));
    plot2.drawLines();
    plot2.drawGridLines(GPlot.VERTICAL);
    plot2.drawGridLines(GPlot.HORIZONTAL);
    plot2.endDraw();
    textSize(16);fill(88, 116, 120); text("Idle Time", 60, 660);
    textSize(16);fill(88, 116, 120); text(nfs(idleM,2,0)+" :"+nfs(idleS,2,0), 62, 680);
    textSize(10);fill(88, 116, 120); text("Developed by TA1718.01.009 - Electrical Engineering ITB and supported by ", 5, 710);
    image(name,375,698);
    saveButton();
    
}

void clock(){
    fill(80);
    noStroke();
    ellipse(cx, cy, clockDiameter, clockDiameter);
    
    // Angles for sin() and cos() start at 3 o'clock;
    // subtract HALF_PI to make them start at the top
    float s = map(second(), 0, 60, 0, TWO_PI) - HALF_PI;
    float m = map(minute() + norm(second(), 0, 60), 0, 60, 0, TWO_PI) - HALF_PI; 
    float h = map(hour() + norm(minute(), 0, 60), 0, 24, 0, TWO_PI * 2) - HALF_PI;
    
    // Draw the hands of the clock
    stroke(255);
    strokeWeight(1);
    line(cx, cy, cx + cos(s) * secondsRadius, cy + sin(s) * secondsRadius);
    strokeWeight(2);
    line(cx, cy, cx + cos(m) * minutesRadius, cy + sin(m) * minutesRadius);
    strokeWeight(4);
    line(cx, cy, cx + cos(h) * hoursRadius, cy + sin(h) * hoursRadius);
    
    // Draw the minute ticks
    strokeWeight(2);
    beginShape(POINTS);
    for (int a = 0; a < 360; a+=6) {
        float angle = radians(a);
        float x = cx + cos(angle) * secondsRadius;
        float y = cy + sin(angle) * secondsRadius;
        vertex(x, y);
    }
    endShape();
}

void engineIndicatorLight(){
    int setColor;
    if(printEngine == 1.0){ //Idle
        setColor = color(143, 194, 102);
        h2 = hour();
        m2 = minute();
        s2 = second();
        idleTime = 3600*(h2-h1)+60*(m2-m1)+s2-s1;
        idleM = idleTime/60;
        idleS = idleTime % 60;
    }
    else if(printEngine == 2.0){ //Starting
        setColor = color(242, 152, 38);
        h1 = hour();
        m1 = minute();
        s1 = second();
    }
    else { //Off
        setColor = color(230, 88, 83);
    }
    fill(setColor);
    noStroke();
    ellipse(840, 53, 50, 50);
}

void displayTime(){

    textSize(18);

    fill(30, 135, 207); text(nfs(dd,2,0), timeX, timeY);
    fill(30, 135, 207); text("-", timeX+27, timeY-2);  
    fill(30, 135, 207); text(nfs(mm,2,0), timeX+31, timeY);
    fill(30, 135, 207); text("-", timeX+58, timeY-2);  
    fill(30, 135, 207); text(nfs(yy,2,0), timeX+62, timeY);

    textSize(25);
    fill(30, 135, 207); text(nfs(h,2,0), timeX, timeY+30);
    fill(30, 135, 207); text(":", timeX+38, timeY-2+30);  
    fill(30, 135, 207); text(nfs(m,2,0), timeX+37, timeY+30);
    fill(30, 135, 207); text(":", timeX+76, timeY-2+30);  
    fill(30, 135, 207); text(nfs(s,2,0), timeX+74, timeY+30);
}

void matGauge(){
    textSize(16); fill(119, 177, 222); text("MAT (C)", matLocX+45, matLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(f_MAT,1,2), matLocX+10, matLocY-30);
    textSize(12); fill(119, 177, 222); text("-40", matLocX-7, matLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("60", matLocX+gaugeSizeX-12, matLocY+gaugeSizeY+30);
    stroke(125); line(matLocX, matLocY+gaugeSizeY, matLocX, matLocY+gaugeSizeY+15);
    stroke(125); line(matLocX+gaugeSizeX, matLocY+gaugeSizeY, matLocX+gaugeSizeX, matLocY+gaugeSizeY+15);
    
    if(f_MAT > 20 && f_MAT < 60){
        for(i=0; i<(f_MAT - matLow) * gaugeSizeX / rangeMAT; i++){
            stroke(143, 194, 102); //green
            line(matLocX+1+i, matLocY+gaugeSizeY, matLocX+1+i, matLocY);
        }
    }
    else if((f_MAT>5) && (f_MAT<=20)){
        for(i=0; i<(f_MAT - matLow) * gaugeSizeX / rangeMAT; i++){
            stroke(248, 169, 65); //orange
            line(matLocX+1+i, matLocY+gaugeSizeY, matLocX+1+i, matLocY);
        }

    }
    else if(f_MAT>=-40 && (f_MAT<=5)){
        for(i=0; i<(f_MAT - matLow) * gaugeSizeX / rangeMAT; i++){
            stroke(230, 88, 83); //red
            line(matLocX+1+i, matLocY+gaugeSizeY, matLocX+1+i, matLocY);
        }
    }
    else if(f_MAT >= 1){
        for(i=0; i<gaugeSizeX; i++){
            stroke(143, 194, 102); //green
            line(matLocX+1+i, matLocY+gaugeSizeY, matLocX+1+i, matLocY);
        }
    }
    shape(rectGauge, matLocX, matLocY);
    shape(bgBox, 0, 245);
    shape(bgBoxPID, 1000, 245);
}

void chtGauge(){
    //CHT GAUGE
    textSize(16); fill(119, 177, 222); text("CHT (C)", chtLocX+45, chtLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(f_CHT,1,2), chtLocX+10, chtLocY-30);
    textSize(12); fill(119, 177, 222); text("20", chtLocX-7, chtLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("250", chtLocX+gaugeSizeX-7, chtLocY+gaugeSizeY+30);
    stroke(125); line(chtLocX, chtLocY+gaugeSizeY, chtLocX, chtLocY+gaugeSizeY+15);
    stroke(125); line(chtLocX+gaugeSizeX, chtLocY+gaugeSizeY, chtLocX+gaugeSizeX, chtLocY+gaugeSizeY+15);
    
    if(f_CHT<150){
        for(i=0; i<(f_CHT - chtLow) * gaugeSizeX / rangeCHT; i++){
            stroke(143, 194, 102); //green
            line(chtLocX+1+i, chtLocY+gaugeSizeY, chtLocX+1+i, matLocY);
        }
    }
    else if((f_CHT>=150) && (f_CHT<200)){
        for(i=0; i<(f_CHT - chtLow) * gaugeSizeX / rangeCHT; i++){
            stroke(248, 169, 65); //orange
            line(chtLocX+1+i, chtLocY+gaugeSizeY, chtLocX+1+i, matLocY);
        }

    }
    else if((f_CHT>=200) && (f_CHT<=250)){
        for(i=0; i<(f_CHT - chtLow) * gaugeSizeX / rangeCHT; i++){
            stroke(230, 88, 83); //red
            line(chtLocX+1+i, chtLocY+gaugeSizeY, chtLocX+1+i, matLocY);
        }
    }
    else{
        for(i=0; i<gaugeSizeX; i++){
            stroke(230, 88, 83); //red
            line(chtLocX+1+i, chtLocY+gaugeSizeY, chtLocX+1+i, matLocY);
        } 
    }
    shape(rectGauge, chtLocX, chtLocY);
}

void pressure(){
    //MAP GAUGE
    textSize(16); fill(119, 177, 222); text("MAP (atm)", pressureLocX+40, pressureLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(f_MAP,1,2), pressureLocX+30, pressureLocY-30);
    textSize(12); fill(119, 177, 222); text("0", pressureLocX-7, pressureLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("1", pressureLocX+gaugeSizeX-7, pressureLocY+gaugeSizeY+30);
    stroke(125); line(pressureLocX, pressureLocY+gaugeSizeY, pressureLocX, pressureLocY+gaugeSizeY+15);
    stroke(125); line(pressureLocX+gaugeSizeX, pressureLocY+gaugeSizeY, pressureLocX+gaugeSizeX, pressureLocY+gaugeSizeY+15);
    
    if((f_MAP > 0.8) && (f_MAP < 1) ){
        for(i=0; i<(f_MAP - mapLow) * gaugeSizeX / rangeMAP; i++){
            stroke(143, 194, 102); //green
            line(pressureLocX+1+i, pressureLocY+gaugeSizeY, pressureLocX+1+i, pressureLocY);
        }
    }
    else if((f_MAP>0.5) && (f_MAP<=0.8)){
        for(i=0; i<(f_MAP - mapLow) * gaugeSizeX / rangeMAP; i++){
            stroke(248, 169, 65); //orange
            line(pressureLocX+1+i, pressureLocY+gaugeSizeY, pressureLocX+1+i, pressureLocY);
        }

    }
    else if(f_MAP>=0 && (f_MAP<=0.5)){
        for(i=0; i<(f_MAP - mapLow) * gaugeSizeX / rangeMAP; i++){
            stroke(230, 88, 83); //red
            line(pressureLocX+1+i, pressureLocY+gaugeSizeY, pressureLocX+1+i, pressureLocY);
        }
    }
    else if(f_MAP >= 1){
        for(i=0; i<gaugeSizeX; i++){
            stroke(143, 194, 102); //green
            line(pressureLocX+1+i, pressureLocY+gaugeSizeY, pressureLocX+1+i, pressureLocY);
        }
    }
    shape(rectGauge, pressureLocX, pressureLocY);
}

void afrGauge(){
    textSize(16); fill(119, 177, 222); text("AFR", afrLocX+60, afrLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(f_Lambda,1,2), afrLocX+30, afrLocY-30);
    textSize(12); fill(119, 177, 222); text("10.0", afrLocX-7, afrLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("20.0", afrLocX+gaugeSizeX-7, afrLocY+gaugeSizeY+30);
    stroke(125); line(afrLocX, afrLocY+gaugeSizeY, afrLocX, afrLocY+gaugeSizeY+15);
    stroke(125); line(afrLocX+gaugeSizeX, afrLocY+gaugeSizeY, afrLocX+gaugeSizeX, afrLocY+gaugeSizeY+15);
    
    if(f_Lambda>=13.3 && f_Lambda<=16.1){
        for(i=0; i<(f_Lambda - lambdaLow) * gaugeSizeX / rangeLambda; i++){
            stroke(143, 194, 102); //green
            line(afrLocX+1+i, afrLocY+gaugeSizeY, afrLocX+1+i, afrLocY);
        }
    }
    else if(((f_Lambda>=12) && (f_Lambda<13.3)) || ((f_Lambda>16.1)&&(f_Lambda<=17.5))){
        for(i=0; i<(f_Lambda - lambdaLow) * gaugeSizeX / rangeLambda; i++){
            stroke(248, 169, 65); //orange
            line(afrLocX+1+i, afrLocY+gaugeSizeY, afrLocX+1+i, afrLocY);
        }

    }
    else{
        for(i=0; i<(f_Lambda - lambdaLow) * gaugeSizeX / rangeLambda; i++){
            stroke(230, 88, 83); //red
            line(afrLocX+1+i, afrLocY+gaugeSizeY, afrLocX+1+i, afrLocY);
        }
    }
    shape(rectGauge, afrLocX, afrLocY);
}

void tpsGauge(){
    textSize(16); fill(119, 177, 222); text("TPS (%)", tpsLocX+60, tpsLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(f_TPS,1,1), tpsLocX+20, tpsLocY-30);
    textSize(12); fill(119, 177, 222); text("0", tpsLocX-7, tpsLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("100", tpsLocX+gaugeSizeX-7, tpsLocY+gaugeSizeY+30);
    stroke(125); line(tpsLocX, tpsLocY+gaugeSizeY, tpsLocX, tpsLocY+gaugeSizeY+15);
    stroke(125); line(tpsLocX+gaugeSizeX, tpsLocY+gaugeSizeY, tpsLocX+gaugeSizeX, tpsLocY+gaugeSizeY+15);
    
    if(f_TPS<10){
        for(i=0; i<(f_TPS - tpsLow) * gaugeSizeX / rangeTPS; i++){
            stroke(143, 194, 102); //green
            line(tpsLocX+1+i, tpsLocY+gaugeSizeY, tpsLocX+1+i, tpsLocY);
        }
    }
    else if((f_TPS>=10) && (f_TPS<50)){
        for(i=0; i<(f_TPS - tpsLow) * gaugeSizeX / rangeTPS; i++){
            stroke(248, 169, 65); //orange
            line(tpsLocX+1+i, tpsLocY+gaugeSizeY, tpsLocX+1+i, tpsLocY);
        }

    }
    else if ((f_TPS>=50) && (f_TPS<=100)){
        for(i=0; i<(f_TPS - tpsLow) * gaugeSizeX / rangeTPS; i++){
            stroke(230, 88, 83); //red
            line(tpsLocX+1+i, tpsLocY+gaugeSizeY, tpsLocX+1+i, tpsLocY);
        }
    }
    else{
        for(i=0; i<gaugeSizeX; i++){
            stroke(230, 88, 83); //red
            line(tpsLocX+1+i, tpsLocY+gaugeSizeY, tpsLocX+1+i, tpsLocY);
        }
    }
    shape(rectGauge, tpsLocX, tpsLocY);
}


void rpmGauge(){
    textSize(16); fill(119, 177, 222); text("RPM", rpmLocX+60, rpmLocY-7);
    textSize(36); fill(119, 177, 222); text(nfs(rpm,1,0), rpmLocX+20, rpmLocY-30);
    textSize(12); fill(119, 177, 222); text("0", rpmLocX-7, rpmLocY+gaugeSizeY+30);
    textSize(12); fill(119, 177, 222); text("8000", rpmLocX+gaugeSizeX-7, rpmLocY+gaugeSizeY+30);
    stroke(125); line(rpmLocX, rpmLocY+gaugeSizeY, rpmLocX, rpmLocY+gaugeSizeY+15);
    stroke(125); line(rpmLocX+gaugeSizeX, rpmLocY+gaugeSizeY, rpmLocX+gaugeSizeX, rpmLocY+gaugeSizeY+15);
    
    if(rpm<3000){
        for(i=0; i<rpm*gaugeSizeX/8000; i++){
            stroke(143, 194, 102); //green
            line(rpmLocX+1+i, rpmLocY+gaugeSizeY, rpmLocX+1+i, rpmLocY);
        }
    }
    else if((rpm>=3000) && (rpm<5000)){
        for(i=0; i < rpm*gaugeSizeX/8000; i++){
            stroke(248, 169, 65); //orange
            line(rpmLocX+1+i, rpmLocY+gaugeSizeY, rpmLocX+1+i, rpmLocY);
        }

    }
    else if ((rpm>=5000) && (rpm<=8000)){
        for(i=0; i<rpm*gaugeSizeX/8000; i++){
            stroke(230, 88, 83); //orange
            line(rpmLocX+1+i, rpmLocY+gaugeSizeY, rpmLocX+1+i, rpmLocY);
        }
    }
    else{
        for(i=0; i<gaugeSizeX; i++){
            stroke(230, 88, 83); //orange
            line(rpmLocX+1+i, rpmLocY+gaugeSizeY, rpmLocX+1+i, rpmLocY);
        }
    }
    shape(rectGauge, rpmLocX, rpmLocY);
}

void fuelCons(){
    textSize(14); fill(255, 255, 255); text("Fuel", pidLocX, pidLocY);
    textSize(14); fill(255, 255, 255); text("Consumption", pidLocX, pidLocY+15);
    textSize(40); fill(255, 255, 255); text(nfs(ccm,1,0), pidLocX-5, pidLocY+50);
    textSize(18); fill(255, 255, 255); text("cc/min", pidLocX+15, pidLocY+70);

    textSize(14); fill(255, 255, 255); text("Total Fuel", pidLocX, pidLocY+150);
    textSize(14); fill(255, 255, 255); text("Consumption", pidLocX, pidLocY+165);
    textSize(40); fill(255, 255, 255); text(nfs(totalCons,1,0), pidLocX-5, pidLocY+200);
    textSize(18); fill(255, 255, 255); text("cc", pidLocX+35, pidLocY+220);
    shape(fuelGauge, pidLocX+20,pidLocY+240);
}


  void serialEvent(Serial myPort) {
    // get the ASCII string:
    String inString = myPort.readStringUntil('\n');

    if (inString != null) {
      // trim off any whitespace:
      inString = trim(inString);
      // split the string on the commas and convert the resulting substrings
      // into an integer array:
      float[] reading = float(split(inString, "\t"));
      // if the array has at least three elements, you know you got the whole
      // thing.  Put the numbers in the color variables:
      if (reading.length >= 10) {
        // map them to the range 0-255:
        time = reading[0];
        f_MAT = reading[1];
        f_CHT = reading[2];
        f_MAP = reading[3];
        f_Lambda = reading[4];
        f_TPS = reading[5];
        rpm = reading[6];
        ccm = reading[7];
        totalCons = reading[8];
        printEngine = reading[9];
        ;
      }
    }
  }

void update(int x, int y) {
    if(overRect(rectX, rectY, rectSizeX, rectSizeY)){
        rectOver = true;
    } else{
        rectOver = false;
    }

    if(overRect(rectX, rectY-20, rectSizeX, rectSizeY-12)){
        textOver = true;
    } else{
        textOver = false;
    }
}

void mousePressed() {
  if (rectOver && mouseButton == LEFT) {
    if(logState == false){
        String dateOnly =str(dd) + "-" + str(mm) + "-" + str(yy);
        String date = dateOnly+ "__" + str(h) + "." + str(m) + "." + str(s);
        String fileName = "Log Repository/"+dateOnly+"/Data Log " + date + "_" +title +".txt";
        output = createWriter(fileName);
        logState = !logState;
        output.println("Log created on " + date);
        output.println(title);
        output.println();
        output.print("Time");output.print("\t");
        output.print("MAT");output.print("\t");
        output.print("CHT");output.print("\t");
        output.print("MAP");output.print("\t");
        output.print("AFR");output.print("\t");
        output.print("TPS");output.print("\t");
        output.print("RPM");output.print("\t");
        output.print("CCM");output.print("\t");
        output.print("Cons");output.print("\t");
        output.println("State");
    } else{
        output.println();
        output.println("================================Data log ends here================================");
        output.print("Idle time = "+nfs(idleM,2,0)+":"+nfs(idleS,2,0));
        output.flush();
        output.close();
        logState = !logState;
    }
  }

  if(textOver && mouseButton == LEFT){
      inputState = true;
  } else if(!(textOver || rectOver) && mouseButton == LEFT){
      inputState = false;
  }

  
}

void keyPressed(){
    if(logState == false && inputState == true){
        if ( (key>='a'&&key<='z') || ( key >= 'A'&&key<='Z')) {
            title+=key; // add this key to our name
        }
        else if ( (key>='0'&&key<='9')||key==' ') {
            title+=key; // add this key to our name
        }
        else if (key==BACKSPACE) {
            if (title.length()>0) {
                title=title.substring(0, title.length()-1);
      }
        } // BACKSPACE
    } 
    
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void saveButton(){
    // Textbox
    textSize(12); fill(255, 255, 255); text("Enter Log Title", rectX, rectY-24);
    if(inputState == false){
        fill(100, 100, 100); rect(rectX, rectY-20, rectSizeX, rectSizeY-12);
        textSize(12); fill(255, 255, 255); text("Click here", rectX+5, rectY-6);
    } else{
        fill(255, 255, 255); rect(rectX, rectY-20, rectSizeX, rectSizeY-12);
        textSize(12); fill(0, 0, 0); text(title, rectX+5, rectY-6);
    }
    
    // Push Button
    fill(87, 115, 119); rect(rectX, rectY, rectSizeX, rectSizeY);
    

    if(logState == false){
        textSize(14); fill(255, 255, 255); text("Start", rectX+25, rectY+13);
        textSize(14); fill(255, 255, 255); text("Logging", rectX+12, rectY+25);
        
    } else{
        fill(140,193,99);
        rect(rectX, rectY, rectSizeX, rectSizeY);
        textSize(14); fill(255, 255, 255); text("Save", rectX+26, rectY+13);
        textSize(14); fill(255, 255, 255); text("Data", rectX+26, rectY+25);
        output.print(time);output.print("\t");
        output.print(f_MAT);output.print("\t");
        output.print(f_CHT);output.print("\t");
        output.print(f_MAP);output.print("\t");
        output.print(f_Lambda);output.print("\t");
        output.print(f_TPS);output.print("\t");
        output.print(rpm);output.print("\t");
        output.print(ccm);output.print("\t");
        output.print(totalCons);output.print("\t");
        output.println(printEngine);
    }
    

}