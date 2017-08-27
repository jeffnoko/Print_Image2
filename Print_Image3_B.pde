//This is a copy of Print_Image2 / Print_Image2.pde in github @jeffnoko

/* README:
 * This code has been modified to optionally print to an emulated painting machine.
 * To use it please start the Image_Printer Processing sketch first
 * (its folder is in this sketch's folder).
 */

import java.io.*;
import java.net.*;
import processing.serial.*;
 
//println(Serial.list()); Serial port = new Serial(this, Serial.list()[0], 9600); // <- uncomment this to run with a real machine
PrintClient port = new PrintClient(); // <- make this a comment to run with a real machine

PImage img;

void setup() {
  size(600, 600);
  //background(0);
   background(random(0,150));

  // Initiate connection to server
  port.connect();

  img = loadImage("beach.jpg");
  img.resize(20, 30);

  println(img.width, img.height);

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
      int i = y * img.width + x ;
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
  //println((char)c);delay(100);
}

// ==== Code below here is used to talk to the emulated machine (in the Image_Printer sketch) ====

public class PrintClient {
  private Socket socket;
  private BufferedReader inputReader;
  private BufferedOutputStream outputWriter;

  public void connect() {
    try {
      socket = new Socket("localhost", 2004);
      System.out.println("Connected to localhost in port 2004");

      outputWriter = new BufferedOutputStream(socket.getOutputStream(), 4096);
      inputReader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
    } catch (UnknownHostException e){
      System.err.println("You are trying to connect to an unknown host!");
      System.exit(1);
    } catch(IOException e){
      e.printStackTrace();
      System.exit(1);
    }
  }

  public int read() {
    try {
      if (inputReader.ready()) {
        return (int)inputReader.read();
      } else {
        return -1;
      }
    } catch (IOException e) {
      e.printStackTrace();
      System.exit(1);
      return -1;
    }
  }

  public void write(int c) {
    try {
      outputWriter.write(c);
      outputWriter.flush();
    } catch (IOException e) {
      e.printStackTrace();
      System.exit(1);
    }
  }
  
  public void close() {
    try {
      inputReader.close();
      outputWriter.close();
      socket.close();
    } catch (IOException e){
      e.printStackTrace();
      System.exit(1);
    }
  }
}