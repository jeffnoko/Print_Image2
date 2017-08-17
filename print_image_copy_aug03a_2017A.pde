import processing.serial.*;

Serial port;
PImage img;

void setup() {
  size(600, 600);
  background(0);
  
  println(Serial.list());
  port = new Serial(this, Serial.list()[0], 9600);
  
  img = loadImage("beach.jpg");
  
  img.resize(20, 30);
  
  img.loadPixels();
  
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      int i = y * img.width + x;
      float b = (256 / 5) * (int)(brightness(img.pixels[i]) / (256 / 5));
      img.pixels[i] = color(b, b, b);
       
    }
   
  }
}

void mousePressed() {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      int i = y * img.width + x;
      float b = (265 / 5) * (int)(brightness(img.pixels[i]) / (256 / 5));
      port.write((char)b);
    }
  }
  
  println("sent image");

}

void draw () {
  image(img, 0, 0, width, height);
  
  int c = port.read();
  
  if (c != -1) print((char)c);
}