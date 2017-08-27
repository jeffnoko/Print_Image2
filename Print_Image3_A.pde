
// This is a copy with some small changes of 
//Print_Image2 / Image_Printer/ Image_Printer.pde in github @jeffnoko

import java.io.*;
import java.net.*;
import java.util.concurrent.*;

void setup() {
  size(640, 480);
  
 // background(255);
 background(random(0,255),random(0,255),random(0,255));
 // frameRate(10000);
   frameRate(100);

  server = new PrintServer();
  (new Thread(server)).start();
}

// If you squint the code below looks like the Arduino firmware
// (probably because it's mostly just copy-pasted from that)

int image[] = new int[20 * 30 +1];

int maxY = 40000 / 4;//     20000  orininal
int maxX = 30000 / 4;//     30000

boolean pixelDrawn = true;
int drawIndex = 0;
boolean done = false; // When true, drawing stops

void tickDrawing() {
  boolean moving = stepper1.isRunning() || stepper2.isRunning();

  if (moving) {
    return;
  }

  if (pixelDrawn) {
    // Start next move
    pixelDrawn = false;

    int x = drawIndex % 20;
    int y = drawIndex / 20;

    stepper2.moveTo(y * (maxY / 30));
    stepper1.moveTo(x * (maxX / 20));
  } else {
    int currentPixel = 0xff - image[drawIndex++];
    sprayOn(currentPixel * 4);
    
    // HACK: See SprayingMachine.run()
    //delay(10);
    //sprayOff();

    pixelDrawn = true;
  }
  
  // Stop when we run out of pixels to draw
  if (drawIndex >= 20 * 30 +1) {
    done = true;
  }
  
}

int pixelIndex = 0;
boolean starting = true;

void draw() {
  // server.available replaces Serial.available here,
  // but the concept is the same - it's consuming data from the "PC" (Print_Image2)
  while (server.available() > 0) {
    int pixel = server.read();
    image[pixelIndex++] = pixel;
  }

  if (pixelIndex >= 20 * 30 - 1) {
    if (starting) {
      server.println("drawing picture");
      starting = false;
    }
    
    if (!done) {
      tickDrawing();
      
    }
    
  }
  if (done){//background(255);
    done = false;
    //background(255);
    //background(random(0,150));
     background(random(0,255),random(0,255),random(0,255));
  drawIndex = 0;}
 //  background(255);
  // This is added to run the machine emulation & networking
  paintingMachine.run();
  
}

// ==== Emulation & networking ====

PrintServer server;
PaintingMachine paintingMachine = new PaintingMachine();
StepperMotor stepper1 = paintingMachine.stepperX;
StepperMotor stepper2 = paintingMachine.stepperY;

void sprayOn(int intensity) {
  paintingMachine.sprayOn(intensity);
}

void sprayOff() {
  paintingMachine.sprayOff();
}

class StepperMotor {
  private float position;
  private int targetPosition;
  private float speed;
  private boolean running;
  
  public StepperMotor(float speed) {
    position = 0;
    running = false;
    this.speed = speed;
  }
  
  public void run() {
    if (abs(position - targetPosition) < speed) {
      position = targetPosition;
      running = false;
    } else {
      position += position < targetPosition ? speed : -speed;
    }
  }
  
  public void moveTo(int position) {
    this.targetPosition = position;
    running = true;
  }
  
  public boolean isRunning() {
    return running;
  }
  
  public float getPosition() {
    return position;
  }
}

class PaintingMachine {
  public StepperMotor stepperX;
  public StepperMotor stepperY;
  
  private boolean spraying;
  private int intensity;
  
  public PaintingMachine() {
    stepperX = new StepperMotor(100);
    stepperY = new StepperMotor(100);
    
    spraying = false;
    intensity = 0;
  }
  
  public void run() {
    float lastX = stepperX.getPosition();
    float lastY = stepperY.getPosition();
    
    stepperX.run();
    stepperY.run();
    
    if (spraying) {
      strokeWeight(15);//16
      stroke(map(intensity, 0, 1023, 255, 0));//0,255
      line(map(lastX, 0, maxX, 0, width), map(lastY, 0, maxY, 0, height), map(stepperX.getPosition(), 0, maxX, 0, width), map(stepperY.getPosition(), 0, maxY, 0, height));
    }
    
    // HACK: to get around that I'm too lazy to implement this such that the original
    // sprayOn, delay, sprayOff would work, this turns off the spray when we start moving
    // which does not match what the actual machine does.
    if (!stepperX.isRunning() && !stepperY.isRunning()) {
      spraying = false;
    }
  }
  
  public void sprayOn(int intensity) {
    if (intensity < 0 || intensity >= 1024) {
      throw new RuntimeException();
    }
    
    spraying = true;
    this.intensity = intensity;
  }
  
  public void sprayOff() {
    spraying = false;
    intensity = 0;
  }
}

public class PrintServer implements Runnable {
  private ServerSocket socket;
  private Socket connection;

  private PrintWriter outputWriter;
  private InputStream inputReader;
  
  private ConcurrentLinkedQueue<Integer> queue;

  boolean dead;
  
  public PrintServer () {
    dead = false;
    queue = new ConcurrentLinkedQueue<Integer>();
  }

  public int available() {
    return queue.size();
  }

  public int read() {
    if (queue.isEmpty()) {
      return -1;
    } else {
      int i = queue.poll();
      if (i == -1) throw new RuntimeException("fuck");
      return i;
    }
  }
  
  void println(String msg) {
    outputWriter.print(msg);
    outputWriter.flush();
  }
  
  void run () {
    try {
      socket = new ServerSocket(2004, 10);

      System.out.println("Waiting for connection");
      connection = socket.accept();

      System.out.println("Connection received from " + connection.getInetAddress().getHostName());

      outputWriter = new PrintWriter(connection.getOutputStream());
      inputReader = connection.getInputStream();

      while (!dead) {
        try {
          int c = inputReader.read();
          
          if (c != -1) {
            queue.add(c);
          }
          
          Thread.sleep(1);
        } catch (InterruptedException e) {
          e.printStackTrace();
          System.exit(1);
        }
      }
    } catch(IOException e) {
      e.printStackTrace();
      System.exit(1);
    } finally {
      try {
        close();
      } catch(IOException e) {
        e.printStackTrace();
        System.exit(1);
      }
    }
  }

  public void close() throws IOException {
    inputReader.close();
    outputWriter.close();
    socket.close();
  }
}