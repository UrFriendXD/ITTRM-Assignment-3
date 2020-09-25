import controlP5.*;

import ddf.minim.*;
import ddf.minim.spi.*; // for AudioRecordingStream
import ddf.minim.ugens.*;

//Audio
Audio audio;
Minim minim;
float speed;

// Array lists
ArrayList<Boid> boids;
ArrayList<Boid> removedBoids;
ArrayList<Avoid> avoids;

float globalScale = .91;

// boid control
float maxSpeed;
float friendRadius;
float crowdRadius;
float avoidRadius;
float coheseRadius;

boolean option_friend = true;
boolean option_crowd = true;
boolean option_avoid = true;
boolean option_noise = true;
boolean option_cohese = true;

// GUI stuff
int messageTimer = 0;
String messageText = "";

// table and time stuff
Table data;
int index = 1; //row of the table
int x = 0;
int y = 0;
boolean isOverUI = false;
String time = " ";


//UI stuff
ControlP5 cp5;

void setup () {
  size(1024, 576);
  textSize(16);
  data = loadTable("peopleCount.csv", "csv" );
  time = data.getString(index, 0);
  recalculateConstants();

  // Initialise the arrays
  boids = new ArrayList<Boid>();
  removedBoids = new ArrayList<Boid>();
  avoids = new ArrayList<Avoid>();
  y = data.getInt(index, 1);

  // Starting amount of boids
  for (int i = 0; i < y; i++) {
    Boid first = new Boid(random(width), random(height));
    boids.add(first);
    first.toBeRemoved = false;
  }

  // Draws buttons
  cp5 = new ControlP5(this);
  cp5.addButton("Next_Day").setValue(0).setPosition(800, 400).setSize(100, 100).setColorForeground(#6C9857).setColorBackground(#84B46F).setColorActive(#6C9857).setFont(createFont("Verdana", 15));
  cp5.addButton("Previous_Day").setValue(0).setPosition(125, 400).setSize(100, 100).setColorBackground(#BF9F70).setColorForeground(#836D4D).setColorActive(#836D4D).setFont(createFont("Verdana", 10));

  setupCircle();

  // Audio initialisation
  minim = new Minim(this);
  audio = new Audio();
}

//method for button "Next"
public void Next_Day() {
  index++;
  time = data.getString(index, 0);
  message("Total amount of people: " + boids.size());
  //println(index); // Debug for index
  changeTime();
}

// Method for button "Previous"
public void Previous_Day() {
  index--;
  time = data.getString(index, 0);
  message("Total amount of people: " + boids.size());
  //println(time); // Debug for time
  changeTime();
}

// Changes the date 
void changeTime() {
  //// Gets x and y in table
  x = data.getInt(index, 0);
  y = data.getInt(index, 1);
  float difference = y - boids.size();
  println(difference);

  // If we need to add, add based on difference else remove based on difference 
  if (difference > 0) {
    for (int i = 0; i < difference; i++) {
      Boid first = new Boid(random(width), random(height));
      boids.add(first);
    }
  } else if (difference < 0) {
    for (int i = 0; i > difference; i--) {
      erase();
    }
  }
}

// Recalculate constants used in boids
void recalculateConstants () {
  maxSpeed = 2.1 * globalScale;
  friendRadius = 60 * globalScale;
  crowdRadius = (friendRadius / 1.3);
  avoidRadius = 90 * globalScale;
  coheseRadius = friendRadius;
}

// Setups the "room" so the boids avoid them
void setupCircle() {
  avoids = new ArrayList<Avoid>();
  //color colour =  color(100, 100, 100);
  for (int x = 0; x < 50; x+= 1) {
    float dir = (x / 50.0) * TWO_PI;
    avoids.add(new Avoid(width * 0.5 + cos(dir) * height*.4, height * 0.5 + sin(dir)*height*.4, color(150, x * 1.5, 100)));
  }
}


void draw () {
  noStroke();
  colorMode(HSB);
  fill(0, 100);
  rect(0, 0, width, height);

  // Calls the draw and go method for each boid
  for (int i = 0; i <boids.size(); i++) {
    Boid current = boids.get(i);
    if (current.isDead) 
    {
      boids.remove(i);
      //removedBoids.remove(current);
    } 
    //println(current.toBeRemoved);
    current.go();
    current.draw();
  }

  // Maybe for removing boids
  if (removedBoids.size() > 0) {
    for (int b = 0; b <removedBoids.size(); b++) {
      Boid current = removedBoids.get(b);
      if (current.isDead) 
      {
        removedBoids.remove(b);
      } 
      current.go();
      current.draw();
    }
  }

  // Calls the draw and go method for each avoid
  for (int i = 0; i <avoids.size(); i++) {
    Avoid current = avoids.get(i);
    current.go();
    current.draw();
  }

  // Timer for the message at the bottom left
  if (messageTimer > 0) {
    messageTimer -= 1;
  }
  drawGUI();


  audio.draw();
}

void drawGUI() {
  if (messageTimer > 0) {
    fill((min(30, messageTimer) / 30.0) * 255.0);
    text(messageText, 10, height - 20);
  }
  fill(#EA0909);
  textSize(20);
  textAlign(CENTER);
  text(time, width/2, height/2);

  textAlign(LEFT);
  fill(#8CBCEA);
  textSize(20);
  text("Control the speed and pitch of the music via mouse position, which also controls the speed of the boids.", 10, 200, 250, 150);

  textSize(20);
  textAlign(RIGHT);
  text("The boids/particles represents the people counters as they enter the room by day", width-260, 200, 250, 150);

  fill(#B65ACB);
  textSize(30);
  textAlign(CENTER);
  text("Covid19: People entering room CB11.00.5", width/2, 35);

  textAlign(LEFT);
  textSize(20);
}

String s(int count) {
  return (count != 1) ? "s" : "";
}

String on(boolean in) {
  return in ? "on" : "off";
}

void mousePressed () {
  // If mouse is over UI, prevents boid spawning
  if (cp5.isMouseOver()) {
    return;
  }
  // Adds boid on left, remove random on right
  switch (mouseButton) {
  case LEFT:
    Boid newBoid = new Boid(mouseX, mouseY);
    boids.add(newBoid);
    message("Total amount of people: " + boids.size());
    break;
  case RIGHT:
    erase();
    break;
  }
  recalculateConstants();
}

// Erased gets called on setup and we don't know why ??? ¯\_(0.0)_/¯
// Sets a random boid to be deleted
void erase () {
  if (boids.size() > 0 ) 
  {
    int boidIndex = int(random(boids.size()));
    Boid randomBoid = boids.get(boidIndex);
    // 
    if (randomBoid.toBeRemoved == false)
    {
      randomBoid.toBeRemoved = true;
      removedBoids.add(randomBoid);
      boids.remove(randomBoid);
    }
  } 
  //println("Test");
}

void drawText (String s, float x, float y) {
  fill(0);
  text(s, x, y);
  fill(200);
  text(s, x-1, y-1);
}


void message (String in) {
  messageText = in;
  messageTimer = (int) frameRate * 3;
}
