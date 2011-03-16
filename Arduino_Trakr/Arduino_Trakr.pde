#include <NewSoftSerial.h>
#include <Wire.h> 
int compassAddress = 0x42 >> 1;

NewSoftSerial tooth(0,1);
int reading = 0;
int serialIndex = 0;
int BUFFERSIZE = 20;
char inBytes[20];

char instBytes[4];
int instPins[4] = {10, 11, 12, 13};

void setup(){
  Wire.begin();
  tooth.begin(115200);
  Serial.begin(115200);
  pinMode(48, OUTPUT);
  digitalWrite(48, HIGH);

  pinMode(instPins[0], OUTPUT);
  pinMode(instPins[1], OUTPUT);
  pinMode(instPins[2], OUTPUT);
  pinMode(instPins[3], OUTPUT);
}

void loop(){
  // Every 10 seconds switch from 
  // one serial GPS device to the other
  if ((millis() / 10000) % 5 != 0){
    if (tooth.available()){
      readSerialInput();
      delay(10);
      Serial.print(inBytes);
    }
  }
  else{
    Serial.print('o');
  }

}


int getHeading(){
  Wire.beginTransmission(compassAddress);  // transmit to device
  // the address specified in the datasheet is 66 (0x42) 
  // but i2c adressing uses the high 7 bits so it's 33 
  Wire.send('A');          // command sensor to measure angle  
  Wire.endTransmission();  // stop transmitting 

  // step 2: wait for readings to happen 
  delay(60);               // datasheet suggests at least 6000 microseconds 

  // step 3: request reading from sensor 
  Wire.requestFrom(compassAddress, 2);  // request 2 bytes from slave device #33 

  // step 4: receive reading from sensor 
  if(2 <= Wire.available()){   // if two bytes were received 
    reading = Wire.receive();   // receive high byte (overwrites previous reading) 
    reading = reading << 8;     // shift high byte to be high 8 bits 
    reading += Wire.receive();  // receive low byte as lower 8 bits 
    reading /= 10;
    return reading;    // print the reading 
  }  
}

char* setPins(char one,char two,char four,char eight) {
  instBytes[0] = one; 
  instBytes[1]= two; 
  instBytes[2] = four;
  instBytes[3] = eight;
  for(int i = 0; i < 4 ; i ++){
    digitalWrite(instPins[i], instBytes[i]);
  }  
  return instBytes;
}

void readSerialInput() {
  while(tooth.available() && serialIndex < BUFFERSIZE) {
    //Store into buffer.
    inBytes[serialIndex] = tooth.read();
    

    //Check for command end.    
    if (inBytes[serialIndex] == '\n' || inBytes[serialIndex] == ';' || inBytes[serialIndex] == '>' || int(inBytes[serialIndex]) == -123) { //Use ; when using Serial Monitor
      inBytes[serialIndex] = '\0'; //end of string char 
      parseCommand(inBytes);
      serialIndex = 0;
    }
    else{
      serialIndex++;
    }
  }
  if(serialIndex >= BUFFERSIZE){
    //buffer overflow, reset the buffer and do nothing
    //TODO: perhaps some sort of feedback to the user?
    for(int j=0; j < BUFFERSIZE; j++){
      inBytes[j] = 0;
      serialIndex = 0;
    }
  }

}
void parseCommand(char* com) {
  Serial.print('parsed');
  if (com[0] == '\0') { 
    return; 
  } //bit of error checking
  int start = 0;
  //get start of command
  while (com[start] != '<'){
    start++; 
    if (com[start] == '\0') {
      //its not there. Must be old version
      start = -1;
      break;
    }
  }
  start++;
  Serial.print(com);
  performCommand(com);
}

void performCommand(char* com) {  
  if (strcmp(com, "f") == 0) { // Forward
    setPins(HIGH,HIGH, HIGH, HIGH);
  } 
  else if (strcmp(com, "r") == 0) { // Right
    setPins(HIGH,HIGH,LOW, LOW);
  } 
  else if (strcmp(com, "l") == 0) { // Left
    setPins(LOW, LOW,HIGH,HIGH);
  } 
  else if (strcmp(com, "b") == 0) { // Backward
    setPins(HIGH,LOW,LOW,HIGH);
  } 
  else if (strcmp(com, "s") == 0) { // Stop
    setPins(LOW, LOW,LOW,LOW);
    Serial.println(getHeading());
  } 
  else if (strcmp(com, "fr") == 0 || strcmp(com, "fz") == 0 || strcmp(com, "x") == 0) { // Read and print forward facing distance sensor
  } 
  else if (strcmp(com, "z") == 0) { // Read and print ground facing distance sensor
  } 
  else if (strcmp(com, "1") == 0 || strcmp(com, "2") == 0 || strcmp(com, "3") == 0 || strcmp(com, "4") == 0 || strcmp(com, "5") == 0 || strcmp(com, "6") == 0 || strcmp(com, "7") == 0 || strcmp(com, "8") == 0 || strcmp(com, "9") == 0 || strcmp(com, "0") == 0) {
    //I know the preceeding condition is dodgy but it will change soon 
  } 
  else if (com[0] == 'c') { // Calibrate center PWM settings for both servos ex: "c 90 90"
  } 
  else if (strcmp(com, "i") == 0) { // Toggle servo to infinite active mode so it doesn't time out automatically

  } 
  else if (com[0] == 'w') { // Handle "wheel" command and translate into PWM values ex: "w -100 100" [range is from -100 to 100]

  } 
  else if (strcmp(com, "reset") == 0) { // Resets the eeprom settings

  } 
  else if (com[0] == 'n') { // Move head up

  } 
  else if (com[0] == 'p') { // Initiates Bluetooth pairing so another device can connect

  } 
  else { 
    Serial.print("e");// Echo unknown command back
    Serial.print(com); 
  }
}

