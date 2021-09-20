import beads.*;
import java.util.*;
import controlP5.*;

//to use text to speech functionality, copy text_to_speech.pde from this sketch to yours
//example usage below

/* 
================================================================ 
INITIALIZATION SECTION 
================================================================ 
*/

// TTS 
String breakSpeech = "Break time! Time to stand up!";

// SamplePlayer and break time gain and glide
SamplePlayer sp;
Gain neckStretchGain;
Glide neckStretchGainGlide;

// sine wave stuff
int waveCount = 10;
float chin2ThroatSineFreq = 659.25; // E note
float thigh2BackSineFreq = 440.0; // A note
float knee2LegSineFreq = 293.66; // D note
float neckStretchSineFreq = 196.00; // G note
Buffer CosineBuffer = new CosineBuffer().getDefault();
float waveIntensity = 1.0;

// Audio fx
Reverb reverb;
float roomSize = 0.0;
float lateReverb = 0.0;

// Array of Glide UGens for series of harmonic frequencies for each wave type (fundamental wave, square, triangle, sawtooth)
Glide[] waveFrequency = new Glide[waveCount];
// Array of Gain UGens for harmonic frequency series amplitudes (i.e. baseFrequency + (1/3)*(baseFrequency*3) + (1/5)*(baseFrequency*5) + ...)
Gain[] waveGain = new Gain[waveCount];

Gain chin2ThroatGain;
Glide chin2ThroatGainGlide;
Gain thigh2BackGain;
Glide thigh2BackGainGlide;
Gain knee2LegGain;
Glide knee2LegGainGlide;

// Array of wave wave generator UGens - will be summed by the corresponding gain to additively synthesize square, triangle, sawtooth waves
WavePlayer[] waveTone = new WavePlayer[waveCount];

// enum used to identify which mode the user is currently in
enum ProgramModeEnum
{
  SETUP, WORK, BREAK;
}

// Initialize program mode to setup at the very beginning
ProgramModeEnum programMode = ProgramModeEnum.SETUP;

// Angle measurements for ISM and WM
float chin2ThroatAngle = 0.0; // acceptable range: 75-105
float thigh2BackAngle = 0.0; // acceptable range: 95-115
float knee2LegAngle = 0.0; // acceptable range: 90-120

// Initial Setup Mode
boolean ismUserPresence = false; // originally at false
boolean ismSetupTracking = false; // originally at false
float ismChin2ThroatTime = 0.0;
float ismThigh2BackTime = 0.0;
float ismKnee2LegTime = 0.0;

// Work Mode
boolean wmPostureTracking = false;
float wmChin2ThroatTime = 0.0;
float wmThigh2BackTime = 0.0;
float wmKnee2LegTime = 0.0;

// Break Mode
boolean bmBreakReminders = false;
boolean bmStandReminders = false;
boolean bmStretchReminders = false;
float bmStandReminderTime = 0.0;
float bmStretchReminderTime = 0.0;
float horizontalNeckAngle = 90.0;
float verticalNeckAngle = 90.0;
int verticalNeckStretches;
int horizontalNeckStretches;

ControlP5 p5;

// Choose mode UI elements
ListBox chooseModeList;

Button cmInitialMode;
Button cmWorkMode;
Button cmBreakMode;

// Initial Setup Mode UI elements
Toggle ismUserPresenceToggle;
Toggle ismSetupTrackingToggle;
Slider ismChin2ThroatAngle;
Slider ismChin2ThroatTimer;
Slider ismThigh2BackAngle;
Slider ismThigh2BackTimer;
Slider ismKnee2LegAngle;
Slider ismKnee2LegTimer;

// Work Mode UI elements
Toggle wmPostureTrackingToggle;
Slider wmChin2ThroatAngle;
Slider wmChin2ThroatTimer;
Slider wmThigh2BackAngle;
Slider wmThigh2BackTimer;
Slider wmKnee2LegAngle;
Slider wmKnee2LegTimer;

// Break Mode UI elements
Toggle bmBreakRemindersToggle;
Toggle bmStandRemindersToggle;
Toggle bmStretchRemindersToggle;
Slider bmStandReminderTimer;
Slider bmStretchReminderTimer;
Slider bmHorizontalNeckAngle;
Slider bmVerticalNeckAngle;

//IMPORTANT (notice from text_to_speech.pde):
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib

TextToSpeechMaker ttsMaker; 

//<import statements here>

//to use this, copy notification.pde, notification_listener.pde and notification_server.pde from this sketch to yours.
//Example usage below.

//name of a file to load from the data directory
String eventDataJSON1 = "Patil_Nishant_Simulator_Setup.json";
String eventDataJSON2 = "Patil_Nishant_Simulator_Work.json";
String eventDataJSON3 = "Patil_Nishant_Simulator_Break.json";

NotificationServer server;
ArrayList<Notification> notifications;

Example example;

//Comparator<Notification> comparator;
//PriorityQueue<Notification> queue;
PriorityQueue<Notification> q2;

/* 
================================================================ 
SETUP SECTION 
================================================================ 
*/

void setup() {
  
  size(1100, 700);
  ac = new AudioContext();
  p5 = new ControlP5(this);
  
  sp = getSamplePlayer("neckStretchLoop.wav");
  sp.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  sp.pause(true);
  
  // chin to throat gain and glide. 
  // Initiate glide to 0 to not annoy users on startup
  chin2ThroatGainGlide = new Glide(ac, 0.0, 200);
  chin2ThroatGain = new Gain(ac, 1, chin2ThroatGainGlide);
  ac.out.addInput(chin2ThroatGain);
  
  // thigh to back gain and glide
  thigh2BackGainGlide = new Glide(ac, 0.0, 200);
  thigh2BackGain = new Gain(ac, 1, thigh2BackGainGlide);
  ac.out.addInput(thigh2BackGain);
  
  // knee to leg gain and glide
  knee2LegGainGlide = new Glide(ac, 0.0, 200);
  knee2LegGain = new Gain(ac, 1, knee2LegGainGlide);
  ac.out.addInput(knee2LegGain);
  
  // neck stretch gain and glide
  neckStretchGainGlide = new Glide(ac, 0.0, 200);
  neckStretchGain = new Gain(ac, 1, neckStretchGainGlide);
  reverb = new Reverb(ac);
  reverb.addInput(sp);
  ac.out.addInput(reverb);
  
  // Neck stretches initialization
  horizontalNeckStretches = 0;
  verticalNeckStretches = 0;
  
  // chin to throat sine wave
  // create a UGen graph to synthesize a sine wave from a base/fundamental frequency and 9 odd harmonics with amplitudes = 1/n
  for( int i = 0, n = 1; i < waveCount; i++, n++) {
    // create the glide that will control this WavePlayer's frequency
    // create an array of Glides in anticipation of connecting them with ControlP5 sliders
    waveFrequency[i] = new Glide(ac, chin2ThroatSineFreq * n, 200);
    
    // Create harmonic frequency WavePlayer - i.e. baseFrequency * 3, baseFrequency * 5, ...
    waveTone[i] = new WavePlayer(ac, waveFrequency[i], Buffer.SINE);
    
    // Create gain coefficients for each harmonic - i.e. 1/3, 1/5, 1/7, ...
     waveIntensity = n == 1 ? 1.0 : 0; // fundamental only
    
    //println(n, ": ", waveIntensity, " * ", chin2ThroatSineFreq * n);
    
    waveGain[i] = new Gain(ac, 1, waveIntensity); // create the gain object
    waveGain[i].addInput(waveTone[i]); // then connect the waveplayer to the gain
  
    // finally, connect the gain to the master gain
    // Gain will sum all of the wave waves, additively synthesizing a square wave tone
    chin2ThroatGain.addInput(waveGain[i]);
  }
  
  
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    waveGain[i].setGain(n == 1 ? 1.0 : 0);
  }
  
  // thigh to back sine wave
  for( int i = 0, n = 1; i < waveCount; i++, n++) {
    // create the glide that will control this WavePlayer's frequency
    // create an array of Glides in anticipation of connecting them with ControlP5 sliders
    waveFrequency[i] = new Glide(ac, thigh2BackSineFreq * n, 200);
    
    // Create harmonic frequency WavePlayer - i.e. baseFrequency * 3, baseFrequency * 5, ...
    waveTone[i] = new WavePlayer(ac, waveFrequency[i], Buffer.SINE);
    
    // Create gain coefficients for each harmonic - i.e. 1/3, 1/5, 1/7, ...
     waveIntensity = n == 1 ? 1.0 : 0; // fundamental only
    
    //println(n, ": ", waveIntensity, " * ", thigh2BackSineFreq * n);
    
    waveGain[i] = new Gain(ac, 1, waveIntensity); // create the gain object
    waveGain[i].addInput(waveTone[i]); // then connect the waveplayer to the gain
  
    // finally, connect the gain to the master gain
    // Gain will sum all of the wave waves, additively synthesizing a square wave tone
    thigh2BackGain.addInput(waveGain[i]);
  }
  
  
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    waveGain[i].setGain(n == 1 ? 1.0 : 0);
  }
  
  // knee to leg sine wave
  for( int i = 0, n = 1; i < waveCount; i++, n++) {
    // create the glide that will control this WavePlayer's frequency
    // create an array of Glides in anticipation of connecting them with ControlP5 sliders
    waveFrequency[i] = new Glide(ac, knee2LegSineFreq * n, 200);
    
    // Create harmonic frequency WavePlayer - i.e. baseFrequency * 3, baseFrequency * 5, ...
    waveTone[i] = new WavePlayer(ac, waveFrequency[i], Buffer.SINE);
    
    // Create gain coefficients for each harmonic - i.e. 1/3, 1/5, 1/7, ...
     waveIntensity = n == 1 ? 1.0 : 0; // fundamental only
    
    //println(n, ": ", waveIntensity, " * ", knee2LegSineFreq * n);
    
    waveGain[i] = new Gain(ac, 1, waveIntensity); // create the gain object
    waveGain[i].addInput(waveTone[i]); // then connect the waveplayer to the gain
  
    // finally, connect the gain to the master gain
    // Gain will sum all of the wave waves, additively synthesizing a square wave tone
    knee2LegGain.addInput(waveGain[i]);
  }
  
  
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    waveGain[i].setGain(n == 1 ? 1.0 : 0);
  }
  
  // UI Section

  // Choose Mode
  cmInitialMode = p5.addButton("cmInitialMode")
    .setPosition(90, 200)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Initial Mode");

  cmWorkMode = p5.addButton("cmWorkMode")
    .setPosition(90, 350)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Work Mode");

  cmBreakMode = p5.addButton("cmBreakMode")
    .setPosition(90, 500)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Break Mode");

  // Initial Setup Mode
  ismUserPresenceToggle = p5.addToggle("ismUserPresenceToggle")
    .setPosition(390, 65)
    .setLabel("");

  ismSetupTrackingToggle = p5.addToggle("ismSetupTrackingToggle")
    .setPosition(390, 105)
    .setLabel("");

  ismChin2ThroatAngle = p5.addSlider("ismChin2ThroatAngle")
    .setPosition(290, 150)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  ismChin2ThroatTimer = p5.addSlider("ismChin2ThroatTimer")
    .setPosition(290, 200)
    .setSize(240, 20)
    .setRange(0, 3)
    .setValue(0)
    .setLabel("");

  ismThigh2BackAngle = p5.addSlider("ismThigh2BackAngle")
    .setPosition(290, 350)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  ismThigh2BackTimer = p5.addSlider("ismThigh2BackTimer")
    .setPosition(290, 400)
    .setSize(240, 20)
    .setRange(0, 3)
    .setValue(0)
    .setLabel("");

  ismKnee2LegAngle = p5.addSlider("ismKnee2LegAngle")
    .setPosition(290, 550)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  ismKnee2LegTimer = p5.addSlider("ismKnee2LegTimer")
    .setPosition(290, 600)
    .setSize(240, 20)
    .setRange(0, 3)
    .setValue(0)
    .setLabel("");

  // Work Mode
  wmPostureTrackingToggle = p5.addToggle("wmPostureTrackingToggle")
    .setPosition(670, 65)
    .setLabel("");

  wmChin2ThroatAngle = p5.addSlider("wmChin2ThroatAngle")
    .setPosition(565, 150)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  wmChin2ThroatTimer = p5.addSlider("wmChin2ThroatTimer")
    .setPosition(565, 200)
    .setSize(240, 20)
    .setRange(0, 5)
    .setValue(0)
    .setLabel("");

  wmThigh2BackAngle = p5.addSlider("wmThigh2BackAngle")
    .setPosition(565, 350)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  wmThigh2BackTimer = p5.addSlider("wmThigh2BackTimer")
    .setPosition(565, 400)
    .setSize(240, 20)
    .setRange(0, 5)
    .setValue(0)
    .setLabel("");

  wmKnee2LegAngle = p5.addSlider("wmKnee2LegAngle")
    .setPosition(565, 550)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(0)
    .setLabel("");

  wmKnee2LegTimer = p5.addSlider("wmKnee2LegTimer")
    .setPosition(565, 600)
    .setSize(240, 20)
    .setRange(0, 5)
    .setValue(0)
    .setLabel("");

  // Break Mode
  bmBreakRemindersToggle = p5.addToggle("bmBreakRemindersToggle")
    .setPosition(940, 65)
    .setLabel("");

  bmStandRemindersToggle = p5.addToggle("bmStandRemindersToggle")
    .setPosition(940, 115)
    .setLabel("");

  bmStretchRemindersToggle = p5.addToggle("bmStretchRemindersToggle")
    .setPosition(940, 165)
    .setLabel("");

  bmStandReminderTimer = p5.addSlider("bmStandReminderTimer")
    .setPosition(840, 250)
    .setSize(240, 20)
    .setRange(0, 45)
    .setValue(0)
    .setLabel("");

  bmStretchReminderTimer = p5.addSlider("bmStretchReminderTimer")
    .setPosition(840, 350)
    .setSize(240, 20)
    .setRange(0, 30)
    .setValue(0)
    .setLabel("");

  bmHorizontalNeckAngle = p5.addSlider("bmHorizontalNeckAngle")
    .setPosition(840, 450)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(90)
    .setLabel("");

  bmVerticalNeckAngle = p5.addSlider("bmVerticalNeckAngle")
    .setPosition(840, 550)
    .setSize(240, 20)
    .setRange(0, 180)
    .setValue(90)
    .setLabel("");

  ac.start();
 
  NotificationComparator priorityComp = new NotificationComparator();
  
  q2 = new PriorityQueue<Notification>(10, priorityComp);
  
  //comparator = new NotificationComparator();
  //queue = new PriorityQueue<Notification>(10, comparator);
  
  //this will create WAV files in your data directory from input speech 
  //which you will then need to hook up to SamplePlayer Beads
  ttsMaker = new TextToSpeechMaker();
  
  //START NotificationServer setup
  server = new NotificationServer();
  
  //instantiating a custom class (seen below) and registering it as a listener to the server
  example = new Example();
  server.addListener(example);
  
  //loading the event stream, which also starts the timer serving events
  server.loadEventStream(eventDataJSON1);
  
  //loading the event stream, which also starts the timer serving events
  //server.loadEventStream(eventDataJSON2);
  
  //loading the event stream, which also starts the timer serving events
  //server.loadEventStream(eventDataJSON3);
  //END NotificationServer setup
}

void draw() {
  background(300);  //fills the canvas with dark blue each frame
  // Mode division texts
  text("Choose Mode", 90, 30);
  text("Initial Setup Mode", 360, 30);
  text("Work Mode", 650, 30);
  text("Break Mode", 930, 30);

  // Initial Setup Mode texts
  text("User presence detected:", 350, 55);
  text("Initial setup tracking:", 350, 95);
  text("Chin to throat angle:", 350, 140);
  text("Chin to throat timer (sec):", 350, 190);
  text("Thigh to back angle:", 350, 340);
  text("Thigh to back timer (sec):", 350, 390);
  text("Knee to leg angle:", 350, 540);
  text("Knee to leg timer (sec):", 350, 590);

  // Work Mode texts
  text("Posture tracking:", 640, 55);
  text("Chin to throat angle:", 610, 140);
  text("Chin to throat timer (min):", 610, 190);
  text("Thigh to back angle:", 610, 340);
  text("Thigh to back timer (min):", 610, 390);
  text("Knee to leg angle:", 610, 540);
  text("Knee to leg timer (min):", 610, 590);

  // Break Mode texts
  text("Break reminders tracking:", 890, 55);
  text("Stand up reminders tracking:", 890, 105);
  text("Stretch reminders tracking:", 890, 155);
  text("Stand up reminder timer (min):", 880, 240);
  text("Stretch reminder timer (min):", 880, 340);
  text("Horizontal axis neck angle:", 880, 440);
  text("Vertical axis neck angle:", 880, 540);

  // Mode division lines
  stroke(126);
  line(275, 0, 275, 700);
  line(550, 0, 550, 700);
  line(825, 0, 825, 700);
}

void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == 'W' || key == 'w') {
    server.stopEventStream(); //always call this before loading a new stream
    server.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: WORK MODE ****");
  }
  //example of stopping the current event stream and loading the second one
  if (key == 'B' || key == 'b') {
    server.stopEventStream(); //always call this before loading a new stream
    server.loadEventStream(eventDataJSON3);
    println("**** New event stream loaded: BREAK MODE ****");
  }  
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class Example implements NotificationListener {
  
  public Example() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    println(notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    //String debugOutput = ">>> ";
    switch (notification.getType()) {
      case SelectISM: {
        cmInitialMode.setColorBackground(0xFF00AAFF);
        cmInitialMode.setColorLabel(0x00000000);
        cmWorkMode.setColorBackground(0xFF002D5A);
        cmWorkMode.setColorLabel(0xFFFFFFFF);
        cmBreakMode.setColorBackground(0xFF002D5A);
        cmBreakMode.setColorLabel(0xFFFFFFFF);        
        programMode = ProgramModeEnum.SETUP;
        break;
      }
      case SetupISM: {
        ismUserPresenceToggle.setValue(1.0);
        ismSetupTrackingToggle.setValue(1.0);
        //ismUserPresence = notification.getISMUserPresence();        
        //ismSetupTracking = notification.getISMSetupTracking();        
        break;
      }      
      case ISMNeckBend: {
        ismChin2ThroatAngle.setValue(notification.getChin2ThroatAngle());
        ismChin2ThroatTimer.setValue(notification.getISMChin2ThroatTime());
        //ismChin2ThroatAngle(notification.getChin2ThroatAngle());
        //ismChin2ThroatTimer(notification.getISMChin2ThroatTime());        
        break;
      }      
      case ISMBackSlouch: {
        ismThigh2BackAngle.setValue(notification.getThigh2BackAngle());
        ismThigh2BackTimer.setValue(notification.getISMThigh2BackTime());
        //ismThigh2BackAngle(notification.getThigh2BackAngle());
        //ismThigh2BackTimer(notification.getISMThigh2BackTime());
        break;
      }      
      case ISMKneeBend: {
        ismKnee2LegAngle.setValue(notification.getKnee2LegAngle());
        ismKnee2LegTimer.setValue(notification.getISMKnee2LegTime());
        //ismKnee2LegAngle(notification.getKnee2LegAngle());
        //ismKnee2LegTimer(notification.getISMKnee2LegTime());
        break;
      }      

      
      case SelectWM: {
        cmInitialMode.setColorBackground(0xFF002D5A);
        cmInitialMode.setColorLabel(0xFFFFFFFF);
        cmWorkMode.setColorBackground(0xFF00AAFF);
        cmWorkMode.setColorLabel(0x00000000);
        cmBreakMode.setColorBackground(0xFF002D5A);
        cmBreakMode.setColorLabel(0xFFFFFFFF);
        programMode = ProgramModeEnum.WORK;
        break;
      }
      case SetupWM: {
        wmPostureTrackingToggle.setValue(1.0);
        //wmPostureTracking = notification.getWMPostureTracking();
        break;
      }      
      case WMNeckBend: {
        wmChin2ThroatAngle.setValue(notification.getChin2ThroatAngle());
        wmChin2ThroatTimer.setValue(notification.getWMChin2ThroatTime());
        //wmChin2ThroatAngle(notification.getChin2ThroatAngle());
        //wmChin2ThroatTimer(notification.getWMChin2ThroatTime());
        break;
      }      
      case WMBackSlouch: {
        wmThigh2BackAngle.setValue(notification.getThigh2BackAngle());
        wmThigh2BackTimer.setValue(notification.getWMThigh2BackTime());
        //wmThigh2BackAngle(notification.getThigh2BackAngle());
        //wmThigh2BackTimer(notification.getWMThigh2BackTime());
        break;
      }      
      case WMKneeBend: {
        wmKnee2LegAngle.setValue(notification.getKnee2LegAngle());
        wmKnee2LegTimer.setValue(notification.getWMKnee2LegTime());
        //wmKnee2LegAngle(notification.getKnee2LegAngle());
        //wmKnee2LegTimer(notification.getWMKnee2LegTime());
        break;
      }      

      
      case SelectBM: {
        cmInitialMode.setColorBackground(0xFF002D5A);
        cmInitialMode.setColorLabel(0xFFFFFFFF);
        cmWorkMode.setColorBackground(0xFF002D5A);
        cmWorkMode.setColorLabel(0xFFFFFFFF);
        cmBreakMode.setColorBackground(0xFF00AAFF);
        cmBreakMode.setColorLabel(0x00000000);
        programMode = ProgramModeEnum.BREAK;
        break;
      }
      case SetupBM: {
        bmBreakRemindersToggle.setValue(1.0);
        bmStandRemindersToggle.setValue(1.0);
        bmStretchRemindersToggle.setValue(1.0);
        //bmBreakReminders = notification.getBMBreakReminders();
        //bmStandReminders = notification.getBMStandReminders();
        //bmStretchReminders = notification.getBMStretchReminders();
        break;
      }      
      case StandupReminder: {
        bmStandReminderTimer.setValue(notification.getBMStandReminderTime());
        //bmStandReminderTimer(notification.getBMStandReminderTime());
        break;
      }      
      case StretchReminder: {
        bmStretchReminderTimer.setValue(notification.getBMStretchReminderTime());
        //bmStretchReminderTimer(notification.getBMStretchReminderTime());
        break;
      }      
      case HorAxNeckAngle: {
        bmHorizontalNeckAngle.setValue(notification.getHorizontalNeckAngle());
        //bmHorizontalNeckAngle(notification.getHorizontalNeckAngle());
        break;
      }      
      case VerAxNeckAngle: {
        bmVerticalNeckAngle.setValue(notification.getVerticalNeckAngle());
        //bmVerticalNeckAngle(notification.getVerticalNeckAngle());
        break;
      }      
    }
    //debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    
    //println(debugOutput);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}


/* 
========================================================
MODE TOGGLES
========================================================
*/

public void cmInitialMode() {
  cmInitialMode.setColorBackground(0xFF00AAFF);
  cmInitialMode.setColorLabel(0x00000000);
  cmWorkMode.setColorBackground(0xFF002D5A);
  cmWorkMode.setColorLabel(0xFFFFFFFF);
  cmBreakMode.setColorBackground(0xFF002D5A);
  cmBreakMode.setColorLabel(0xFFFFFFFF);        
  programMode = ProgramModeEnum.SETUP;
  println("Now on initial setup mode");
}

public void cmWorkMode() {
  cmInitialMode.setColorBackground(0xFF002D5A);
  cmInitialMode.setColorLabel(0xFFFFFFFF);
  cmWorkMode.setColorBackground(0xFF00AAFF);
  cmWorkMode.setColorLabel(0x00000000);
  cmBreakMode.setColorBackground(0xFF002D5A);
  cmBreakMode.setColorLabel(0xFFFFFFFF);
  programMode = ProgramModeEnum.WORK; 
  println("Now on work mode");
}

public void cmBreakMode() {
  cmInitialMode.setColorBackground(0xFF002D5A);
  cmInitialMode.setColorLabel(0xFFFFFFFF);
  cmWorkMode.setColorBackground(0xFF002D5A);
  cmWorkMode.setColorLabel(0xFFFFFFFF);
  cmBreakMode.setColorBackground(0xFF00AAFF);
  cmBreakMode.setColorLabel(0x00000000);
  programMode = ProgramModeEnum.BREAK;
  println("Now on break mode");
}

// Toggle code
public void ismUserPresenceToggle() {
  ismUserPresence = !ismUserPresence;
  println("User presence: " + ismUserPresence);
}

public void ismSetupTrackingToggle() {
  ismSetupTracking = !ismSetupTracking;
  println("Setup tracking: " + ismSetupTracking);
}

public void wmPostureTrackingToggle() {
  wmPostureTracking = !wmPostureTracking;
  println("Posture tracking: " + wmPostureTracking);
}

public void bmBreakRemindersToggle() {
  bmBreakReminders = !bmBreakReminders;
  println("Break reminders: " + bmBreakReminders);
}

public void bmStandRemindersToggle() {
  bmStandReminders = !bmStandReminders;
  println("Stand up reminders: " + bmStandReminders);
}

public void bmStretchRemindersToggle() {
  bmStretchReminders = !bmStretchReminders;
  println("Stretch reminders: " + bmStretchReminders);
}

// ISM event handling
public void ismChin2ThroatAngle(float value) {
  // if in setup mode
  if (programMode == ProgramModeEnum.SETUP) {
    // if both ISM toggles are on
    if (ismUserPresence == true && ismSetupTracking == true) {
      // ismChin2ThroatAngle.setValue(value);
      // p5.getController("ismChin2ThroatAngle").setValue(value);
      chin2ThroatAngle = value;
      println("ISM Chin to throat angle: " + value + " degrees");
      if ((chin2ThroatAngle < 75.0 || chin2ThroatAngle > 105.0) && ismChin2ThroatTime < 3.0) {
       // chin to throat angle out of acceptable range
       println("Fix chin to throat angle! Angle: " + chin2ThroatAngle + " degrees"); 
       
       // set gain value for chin-to-throat sine wave appropriately
       if (chin2ThroatAngle < 75.0) {
         chin2ThroatGainGlide.setValue((75-value)/100.0);
       }
       if (chin2ThroatAngle > 105.0) {
          chin2ThroatGainGlide.setValue((value-105)/100.0);
       }
      } else {
        // set corresponding sine wave gain to 0 because acceptable range of angles
        chin2ThroatGainGlide.setValue(0);
      }
    }
  }
}

public void ismChin2ThroatTimer(float value) {
  if (programMode == ProgramModeEnum.SETUP) {
    if (ismUserPresence == true && ismSetupTracking == true) {
      ismChin2ThroatTime = value;
      println("ISM Chin to throat time: " + ismChin2ThroatTime + " seconds");
    }
  }
}

public void ismThigh2BackAngle(float value) {
  if (programMode == ProgramModeEnum.SETUP) {
    if (ismUserPresence == true && ismSetupTracking == true) {
      thigh2BackAngle = value;
      println("ISM thigh to back angle: " + value + " degrees");
      
     if ((thigh2BackAngle < 95.0 || thigh2BackAngle > 115.0) && ismThigh2BackTime < 3.0) {
       // thigh to back angle out of acceptable range
       println("Fix thigh to back angle! Angle: " + thigh2BackAngle + " degrees");
       
       // set gain value for thigh-to-back sine wave appropriately
       if (thigh2BackAngle < 95.0) {
         thigh2BackGainGlide.setValue((95-value)/100.0);
       }
       if (thigh2BackAngle > 115.0) {
          thigh2BackGainGlide.setValue((value-115)/100.0);
       }
      } else {
        // set corresponding sine wave gain to 0 because acceptable range of angles
        thigh2BackGainGlide.setValue(0);
      }
    }
  }
}

public void ismThigh2BackTimer(float value) {
  if (programMode == ProgramModeEnum.SETUP) {
    if (ismUserPresence == true && ismSetupTracking == true) {
      ismThigh2BackTime = value;
      println("ISM thigh to back time: " + ismThigh2BackTime + " seconds");
    }
  }
}

public void ismKnee2LegAngle(float value) {
  if (programMode == ProgramModeEnum.SETUP) {
    if (ismUserPresence == true && ismSetupTracking == true) {
      knee2LegAngle = value;
      println("ISM thigh to back angle: " + value + " degrees");
      if ((knee2LegAngle < 90.0 || knee2LegAngle > 120.0) && ismKnee2LegTime < 3.0) {
       // knee to leg angle out of acceptable range
       println("Fix knee to leg angle! Angle: " + knee2LegAngle + " degrees");
       
       // set gain value for knee-to-leg sine wave appropriately
       if (knee2LegAngle < 90.0) {
         knee2LegGainGlide.setValue((90-value)/100.0);
       }
       if (knee2LegAngle > 120.0) {
         knee2LegGainGlide.setValue((value-120)/100.0);
       }
      } else {
        // set corresponding sine wave gain to 0 because acceptable range of angles
        knee2LegGainGlide.setValue(0);
      }
    }
  }
}

public void ismKnee2LegTimer(float value) {
  if (programMode == ProgramModeEnum.SETUP) {
    if (ismUserPresence == true && ismSetupTracking == true) {
      ismKnee2LegTime = value;
      println("ISM thigh to back time: " + ismKnee2LegTime + " seconds");
    }
  }
}

// WM event handling
public void wmChin2ThroatAngle(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      chin2ThroatAngle = value;
      println("WM chin to throat angle: " + value + " degrees");
      if ((chin2ThroatAngle < 75.0 || chin2ThroatAngle > 105.0) && wmChin2ThroatTime == 5.0) {
       // chin to throat angle out of acceptable range
       println("Fix chin to throat angle! Angle: " + chin2ThroatAngle + " degrees");
       
       // set gain value for chin-to-throat sine wave appropriately
       if (chin2ThroatAngle < 75.0) {
         chin2ThroatGainGlide.setValue((75-value)/100.0);
       }
       if (chin2ThroatAngle > 105.0) {
          chin2ThroatGainGlide.setValue((value-105)/100.0);
       }
      } else {
       // acceptable range, silence the sine wave
       chin2ThroatGainGlide.setValue(0); 
      }
    }
  }
}

public void wmChin2ThroatTimer(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      wmChin2ThroatTime = value;
      println("WM chin to throat time: " + wmChin2ThroatTime + " seconds");
    }
  }
}

public void wmThigh2BackAngle(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      thigh2BackAngle = value;
      println("WM thigh to back angle: " + thigh2BackAngle + " degrees");
      if ((thigh2BackAngle < 95.0 || thigh2BackAngle > 115.0) && wmThigh2BackTime == 5.0) {
       // thigh to back angle out of acceptable range
       println("Fix thigh to back angle! Angle: " + thigh2BackAngle + " degrees");
       
       // set gain value for thigh-to-back sine wave appropriately
       if (thigh2BackAngle < 95.0) {
         thigh2BackGainGlide.setValue((95-value)/100.0);
       }
       if (thigh2BackAngle > 115.0) {
          thigh2BackGainGlide.setValue((value-115)/100.0);
       }
      } else {
        // acceptable range, silence sine wave
        thigh2BackGainGlide.setValue(0);
      }
    }
  }
}

public void wmThigh2BackTimer(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      wmThigh2BackTime = value;
      println("WM thigh to back time: " + wmThigh2BackTime + " seconds");
    }
  }
}

public void wmKnee2LegAngle(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      knee2LegAngle = value;
      println("WM knee to leg angle: " + knee2LegAngle + " degrees");
      if ((knee2LegAngle < 90.0 || knee2LegAngle > 120.0) && wmKnee2LegTime == 5.0) {
       // knee to leg angle out of acceptable range
       println("Fix knee to leg angle! Angle: " + knee2LegAngle + " degrees");
       
       // set gain value for knee-to-leg sine wave appropriately
       if (knee2LegAngle < 90.0) {
         knee2LegGainGlide.setValue((90-value)/100.0);
       }
       if (knee2LegAngle > 120.0) {
         knee2LegGainGlide.setValue((value-120)/100.0);
       }
      } else {
       knee2LegGainGlide.setValue(0); 
      }
    }
  }
}

public void wmKnee2LegTimer(float value) {
  if (programMode == ProgramModeEnum.WORK) {
    if (ismUserPresence == true && wmPostureTracking == true) {
      wmKnee2LegTime = value;
      println("WM knee to leg time: " + wmKnee2LegTime + " seconds");
    }
  }
}

// BM event handling
public void bmStandReminderTimer(float value) {
  if (programMode == ProgramModeEnum.BREAK) {
    if (ismUserPresence == true && bmBreakReminders == true && bmStandReminders == true) {
      bmStandReminderTime = value;
      println("Duration user has been sitting: " + bmStandReminderTime + " minutes");
      if (bmStandReminderTime == 45.0) {
       // Timer has hit the limit
       println("Time to take a break! Stand up!");
       // TTS reminder
       ttsExamplePlayback(breakSpeech);
      }
    }
  }
}

public void bmStretchReminderTimer(float value) {
  if (programMode == ProgramModeEnum.BREAK) {
    if (ismUserPresence == true && bmBreakReminders == true && bmStretchReminders == true) {
      bmStretchReminderTime = value;
      println("Duration user has been sitting: " + bmStretchReminderTime + " minutes");
      if (bmStretchReminderTime == 30.0) {
        // Timer has hit the limit
        println("Time to take a break! Stretch your neck!");
        // TTS reminder
        sp.pause(false);
        horizontalNeckStretches = 0;
        verticalNeckStretches = 0;
        neckStretchGainGlide.setValue(0.2);
      }
    }
  }
}

public void bmHorizontalNeckAngle(float value) {
  if (programMode == ProgramModeEnum.BREAK) {
    if (ismUserPresence == true && bmBreakReminders == true && bmStretchReminders == true && bmStretchReminderTime == 30.0) {
      horizontalNeckAngle = value;
      println("Horizontal neck angle: " + horizontalNeckAngle + " degrees");
      if (horizontalNeckAngle <= 90) {
        reverb.setSize(value/180.0);
      } else {
        reverb.setSize((180-value)/180.0);
      }
      
      if (horizontalNeckAngle == 0.0) {
        // Neck stretched to the left
        println("Neck stretched to the left");
        horizontalNeckStretches++;
      }
      if (horizontalNeckAngle == 180) {
        println("Neck stretched to the right");
        horizontalNeckStretches++;
      }
      
      if (horizontalNeckStretches >= 2 && verticalNeckStretches >= 2) {
       sp.pause(true); 
       //bmStretchReminderTimer(0.0);
       bmStretchReminderTimer.setValue(0.0);
       //bmVerticalNeckAngle.setValue(90.0);
       //verticalNeckAngle = 90.0;
       //bmHorizontalNeckAngle.setValue(90.0);
       //horizontalNeckAngle = 90.0;
      }
    }
  }
}

public void bmVerticalNeckAngle(float value) {
  if (programMode == ProgramModeEnum.BREAK) {
    if (ismUserPresence == true && bmBreakReminders == true && bmStretchReminders == true && bmStretchReminderTime == 30.0) {
      verticalNeckAngle = value;
      
      if (verticalNeckAngle <= 90) {
        reverb.setDamping(value/180.0);
      } else {
        reverb.setDamping((180-value)/180.0);
      }
      
      println("Vertical neck angle: " + verticalNeckAngle + " degrees");
      if (verticalNeckAngle == 0.0) {
        // Neck stretched to the left
        println("Neck stretched down");
        verticalNeckStretches++;;
      }
      if (verticalNeckAngle == 180) {
        println("Neck stretched up");
        verticalNeckStretches++;
      }
      if (horizontalNeckStretches >= 2 && verticalNeckStretches >= 2) {
       sp.pause(true);
       //bmStretchReminderTimer(0.0);
       bmStretchReminderTimer.setValue(0.0);
       //bmVerticalNeckAngle.setValue(90.0);
       //verticalNeckAngle = 90.0;
       //bmHorizontalNeckAngle.setValue(90.0);
       //horizontalNeckAngle = 90.0;
      }
    }
  }
}
