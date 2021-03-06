// A simple ripple effect. Click on the image to produce a ripple
// Author: radio79
// Code adapted from http://www.neilwallis.com/java/water.html

import SimpleOpenNI.*;
SimpleOpenNI  context;

import java.awt.*;


float zoomF = 0.5f;
float rotX = radians(180);
float rotY = radians(0);

PImage img;
Ripple ripple;

void init() {
  frame.removeNotify();
  frame.setUndecorated(true);
  frame.addNotify();
  super.init();  
}

void setup() {
  context = new SimpleOpenNI(this);
  context.enableDepth();
  context.enableUser();
  
  img = loadImage("data/rainbow.jpeg");
  img.resize(displayWidth, displayHeight);
//  img.resize(1920, 1080);
//  size(img.width, img.height, P3D);
  size(displayWidth, displayHeight, P3D);
  frame.setLocation(0,0);
  
  perspective(radians(30),
                float(width)/float(height),
                10,150000);
  background(0);
  ripple = new Ripple();
  frameRate(120);
}

void draw() {
  context.update();
  loadPixels();
  img.loadPixels();
  for (int loc = 0; loc < width * height; loc++) {
    pixels[loc] = ripple.col[loc];
  }
  
  short ripplemap[];
  ripplemap = ripple.ripplemap;
  int sum = 0;
  for(int i=0;i<ripplemap.length;i++){
    sum += abs(int(ripplemap[i]));
  }
  sum /= (width*height);
//  println((int)((random(sum)/53)*255));
  updatePixels();
  ripple.newframe();
  
  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(-1,1);
  scale(zoomF);
  
  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps   = 2;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;
 
  translate(0,0,-1000);  // set the rotation center of the scene 1000 infront of the camera

  // draw the pointcloud
  beginShape(POINTS);
//  stroke((int)((random(sum)/53)*255), 0, 0);
  for(int y=0;y < context.depthHeight();y+=steps){
    for(int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
        { 
        // draw the projected point
        realWorldPoint = context.depthMapRealWorld()[index];
        if(userMap[index] != 0) {
//          colorMode(HSB, 100);
//            stroke(255, 255, 255);
//          if (random(52)<sum){
//            stroke(255-(int)((random(sum)/53)*255), 0, 0);
////            stroke(255-(int)((random(sum)/53)*255), 255-(int)((random(sum)/53)*255), 255-(int)((random(sum)/53)*255)); 
//          }else{
//            stroke(255, 255, 255);
//          }
          
          stroke(255, 255, 255);
          strokeWeight(2);
//          stroke(255-(int)((random(sum)/53)*255), 0, 0); 
//          ellipse(width/2, height/2, 150, 150);     
          vertex(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
        }
      }
    } 
  } 
  endShape();

  int[] userList = context.getUsers();
  for(int i=0; i<userList.length; i++){
    if(context.isTrackingSkeleton(userList[i])){
      PVector left = new PVector();
      PVector right = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, left);
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, right);
      disturbrip(int(-left.x/2+width/2), int(-left.y/2+height/2));
      disturbrip(int(-right.x/2+width/2), int(-right.y/2+height/2));
    }
    
  }
}

class Ripple {
  int i, a, b;
  int oldind, newind, mapind;
  short ripplemap[]; // the height map
  int col[]; // the actual pixels
  int riprad;
  int rwidth, rheight;
  int ttexture[];
  int ssize;

  Ripple() {
    // constructor
    riprad = 4;
    rwidth = width >> 1;
    rheight = height >> 1;
    ssize = width * (height + 2) * 2;
    ripplemap = new short[ssize];
    col = new int[width * height];
    ttexture = new int[width * height];
    oldind = width;
    newind = width * (height + 3);
  }



  void newframe() {
    // update the height map and the image
    i = oldind;
    oldind = newind;
    newind = i;

    i = 0;
    mapind = oldind;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        short data = (short)((ripplemap[mapind - width] + ripplemap[mapind + width] + 
          ripplemap[mapind - 1] + ripplemap[mapind + 1]) >> 1);
        data -= ripplemap[newind + i];
        data -= data >> 6;
        if (x == 0 || y == 0) // avoid the wraparound effect
          ripplemap[newind + i] = 0;
        else
          ripplemap[newind + i] = data;

        // where data = 0 then still, where data > 0 then wave
        data = (short)(1024 - data);

        // offsets
        a = ((x - rwidth) * data / 1024) + rwidth;
        b = ((y - rheight) * data / 1024) + rheight;

        //bounds check
        if (a >= width) 
          a = width - 1;
        if (a < 0) 
          a = 0;
        if (b >= height) 
          b = height-1;
        if (b < 0) 
          b=0;

        col[i] = img.pixels[a + (b * width)];
        mapind++;
        i++;
      }
    }
  }
}

void onNewUser(SimpleOpenNI curContext, int userId){
  context.startTrackingSkeleton(userId);
}

void disturbrip(int x, int y){
  for (int j = y - ripple.riprad; j < y + ripple.riprad; j++) {
    for (int k = x - ripple.riprad; k < x + ripple.riprad; k++) {
      if (j >= 0 && j < height && k>= 0 && k < width) {
        ripple.ripplemap[ripple.oldind + (j * width) + k] += 512;
      }
    }
  }
}

void keyPressed(){
  if (key=='f'){
    img = loadImage("data/fire.jpeg");
  }else if (key=='s'){
    img = loadImage("data/space.jpeg");
  }else if (key=='r'){
    img = loadImage("data/rainbow.jpeg");
  }
  img.resize(displayWidth, displayHeight);
}

//void mouseDragged(){
//  for (int j = mouseY - ripple.riprad; j < mouseY + ripple.riprad; j++) {
//    for (int k = mouseX - ripple.riprad; k < mouseX + ripple.riprad; k++) {
//      if (j >= 0 && j < height && k>= 0 && k < width) {
//        ripple.ripplemap[ripple.oldind + (j * width) + k] += 512;
//      }
//    }
//  }
//}
