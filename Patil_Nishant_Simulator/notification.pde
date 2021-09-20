enum NotificationType { SelectISM, SetupISM, ISMNeckBend, ISMBackSlouch, ISMKneeBend, 
                        SelectWM, SetupWM, WMNeckBend, WMBackSlouch, WMKneeBend, 
                        SelectBM, SetupBM, StandupReminder, StretchReminder, HorAxNeckAngle, VerAxNeckAngle }
class Notification {
   
  int timestamp;
  NotificationType type; // WorkEvent
  String note;
  String location;
  String tag;
  String flag;
  int priority;
  
  String programMode;
  boolean ismUserPresence;
  boolean ismSetupTracking;
  float chin2ThroatAngle;
  float ismChin2ThroatTime;
  float thigh2BackAngle; 
  float ismThigh2BackTime; 
  float knee2LegAngle; 
  float ismKnee2LegTime; 
  
  boolean wmPostureTracking;
  float wmChin2ThroatTime;
  float wmThigh2BackTime;
  float wmKnee2LegTime;
  
  boolean bmBreakReminders;
  boolean bmStandReminders;
  boolean bmStretchReminders;
  float bmStandReminderTime;
  float bmStretchReminderTime;
  float horizontalNeckAngle;
  float verticalNeckAngle;
  
  public Notification(JSONObject json) {
    this.timestamp = json.getInt("timestamp");
    //time in milliseconds for playback from sketch start
    
    try {
      programMode = json.getString("mode");
    }
    catch (Exception e){
    }
    
    try {
      ismUserPresence = json.getBoolean("ismUserPresence");
    }
    catch (Exception e) {
    }
    
    try {
      ismSetupTracking = json.getBoolean("ismSetupTracking");
    }
    catch (Exception e) {
    }
    
    try {
      this.chin2ThroatAngle = json.getFloat("chin2ThroatAngle");
    }
    catch (Exception e) {
    }
    
    try {
      this.ismChin2ThroatTime = json.getFloat("ismChin2ThroatTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.thigh2BackAngle = json.getFloat("thigh2BackAngle");
    }
    catch (Exception e) {
    }
    
    try {
      this.ismThigh2BackTime = json.getFloat("ismThigh2BackTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.knee2LegAngle = json.getFloat("knee2LegAngle");
    }
    catch (Exception e) {
    }
    
    try {
      this.ismKnee2LegTime = json.getFloat("ismKnee2LegTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.wmPostureTracking = json.getBoolean("wmPostureTracking");
    }
    catch (Exception e) {
    }
    
    try {
      this.wmChin2ThroatTime = json.getFloat("wmChin2ThroatTime");
    }
    catch (Exception e) {
    }
   
    try {
      this.wmThigh2BackTime = json.getFloat("wmThigh2BackTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.wmKnee2LegTime = json.getFloat("wmKnee2LegTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.bmBreakReminders = json.getBoolean("bmBreakReminders");
    }
    catch (Exception e) {
    }
    
    try {
      this.bmStandReminders = json.getBoolean("bmStandReminders");
    }
    catch (Exception e) {
    }
    
    try {
      this.bmStretchReminders = json.getBoolean("bmStretchReminders");
    }
    catch (Exception e) {
    }
    
    try {
      this.bmStandReminderTime = json.getFloat("bmStandReminderTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.bmStretchReminderTime = json.getFloat("bmStretchReminderTime");
    }
    catch (Exception e) {
    }
    
    try {
      this.horizontalNeckAngle = json.getFloat("horizontalNeckAngle");
    }
    catch (Exception e) {
    }
    
    try {
      this.verticalNeckAngle = json.getFloat("verticalNeckAngle");
    }
    catch (Exception e) {
    }
    
    
    String typeString = json.getString("type");
    
    try {
      this.type = NotificationType.valueOf(typeString);
    }
    catch (IllegalArgumentException e) {
      throw new RuntimeException(typeString + " is not a valid value for enum NotificationType.");
    }
    
    
    if (json.isNull("note")) {
      this.note = "";
    }
    else {
      this.note = json.getString("note");
    }
    
    if (json.isNull("location")) {
      this.location = "";
    }
    else {
      this.location = json.getString("location");      
    }
    
    if (json.isNull("tag")) {
      this.tag = "";
    }
    else {
      this.tag = json.getString("tag");      
    }
    
    if (json.isNull("flag")) {
      this.flag = "";
    }
    else {
      this.flag = json.getString("flag");      
    }
    
    this.priority = json.getInt("priority");
    //1-3 levels (1 is highest, 3 is lowest)    
  }
  
  public String getMode() { return programMode; }
  public int getTimestamp() { return timestamp; }
  public NotificationType getType() { return type; }
  public String getNote() { return note; }
  public String getLocation() { return location; }
  public String getTag() { return tag; }
  public String getFlag() { return flag; }
  public int getPriorityLevel() { return priority; }

  public boolean getISMUserPresence() { return ismUserPresence; }
  public boolean getISMSetupTracking() { return ismSetupTracking; }

  public float getChin2ThroatAngle() { return chin2ThroatAngle; }
  public float getISMChin2ThroatTime() { return ismChin2ThroatTime; }  
  public float getThigh2BackAngle() { return thigh2BackAngle; }
  public float getISMThigh2BackTime() { return ismThigh2BackTime; }  
  public float getKnee2LegAngle() { return knee2LegAngle; }
  public float getISMKnee2LegTime() { return ismKnee2LegTime; }  
  
  public boolean getWMPostureTracking() { return wmPostureTracking; }
  public float getWMChin2ThroatTime() { return wmChin2ThroatTime; }  
  public float getWMThigh2BackTime() { return wmThigh2BackTime; }  
  public float getWMKnee2LegTime() { return wmKnee2LegTime; }  

  public boolean getBMBreakReminders() { return bmBreakReminders; }
  public boolean getBMStandReminders() { return bmStandReminders; }
  public boolean getBMStretchReminders() { return bmStretchReminders; }

  public float getBMStandReminderTime() { return bmStandReminderTime; }
  public float getBMStretchReminderTime() { return bmStretchReminderTime; }
  public float getHorizontalNeckAngle() { return horizontalNeckAngle; }
  public float getVerticalNeckAngle() { return verticalNeckAngle; }

  public String toString() {
      String output = getType().toString() + ": ";
      output += "(program mode: " + getMode() + ") ";
      output += "(tag: " + getTag() + ") ";
      output += "(flag: " + getFlag() + ") ";
      output += "(priority: " + getPriorityLevel() + ") ";
      output += "(note: " + getNote() + ") ";    
      output += "(flag: " + getFlag() + ") ";
      output += "(priority: " + getPriorityLevel() + ") ";
      output += "(note: " + getNote() + ") ";
      output += "(ismUserPresence: " + getISMUserPresence() + ") ";
      output += "(ismSetupTracking: " + getISMSetupTracking() + ") ";
      output += "(chin2ThroatAngle: " + getChin2ThroatAngle() + ") ";
      output += "(ismChin2ThroatTime: " + getISMChin2ThroatTime() + ") ";
      output += "(thigh2BackAngle: " + getThigh2BackAngle() + ") ";
      output += "(ismThigh2BackTime: " + getISMThigh2BackTime() + ") ";
      output += "(knee2LegAngle: " + getKnee2LegAngle() + ") ";
      output += "(ismKnee2LegTime: " + getISMKnee2LegTime() + ") ";
  
      output += "(wmPostureTracking: " + getWMPostureTracking() + ") ";
      output += "(wmChin2ThroatTime: " + getWMChin2ThroatTime() + ") ";
      output += "(wmThigh2BackTime: " + getWMThigh2BackTime() + ") ";
      output += "(wmKnee2LegTime: " + getWMKnee2LegTime() + ") ";

      output += "(bmBreakReminders: " + getBMBreakReminders() + ") ";
      output += "(bmStandReminders: " + getBMStandReminders() + ") ";
      output += "(bmStretchReminders: " + getBMStretchReminders() + ") ";
  
      output += "(bmStandReminderTime: " + getBMStandReminderTime() + ") ";
      output += "(bmStretchReminderTime: " + getBMStretchReminderTime() + ") ";
      output += "(horizontalNeckAngle: " + getHorizontalNeckAngle() + ") ";
      output += "(verticalNeckAngle: " + getVerticalNeckAngle() + ") ";
      
      return output;
    }
}
