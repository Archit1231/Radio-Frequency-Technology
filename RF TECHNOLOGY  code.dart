enum TrafficState {
  LANE1_GREEN,
  LANE1_YELLOW,
  LANE2_GREEN,
  LANE2_YELLOW
};

TrafficState currentState = LANE1_GREEN;

unsigned long lastStateChange = 0;
unsigned long lastSerialUpdate = 0;
unsigned long emergencyStart = 0;
bool emergencyMode = false;

const int lane1Red = 2;
const int lane1Yellow = 3;
const int lane1Green = 4;
const int lane2Red = 5;
const int lane2Yellow = 6;
const int lane2Green = 7;
const int emergencyButton = A0;

void setup() {
  pinMode(lane1Red, OUTPUT);
  pinMode(lane1Yellow, OUTPUT);
  pinMode(lane1Green, OUTPUT);
  pinMode(lane2Red, OUTPUT);
  pinMode(lane2Yellow, OUTPUT);
  pinMode(lane2Green, OUTPUT);
  pinMode(emergencyButton, INPUT_PULLUP);

  Serial.begin(9600);
  setLights(currentState);
  Serial.println("Traffic Light FSM Started");
}

void loop() {
  unsigned long now = millis();

  // Emergency Button Handler
  if (digitalRead(emergencyButton) == LOW && !emergencyMode) {
    emergencyMode = true;
    emergencyStart = now;
    changeState(LANE1_GREEN);
    Serial.println("!!! EMERGENCY MODE ACTIVATED !!!");
  }

  // FSM Time-based State Transition
  if (emergencyMode) {
    if (now - emergencyStart >= 10000) {
      emergencyMode = false;
      changeState(LANE1_YELLOW); // Resume normal cycle
    }
  } else {
    switch (currentState) {
      case LANE1_GREEN:
        if (now - lastStateChange >= 10000) changeState(LANE1_YELLOW);
        break;
      case LANE1_YELLOW:
        if (now - lastStateChange >= 3000) changeState(LANE2_GREEN);
        break;
      case LANE2_GREEN:
        if (now - lastStateChange >= 10000) changeState(LANE2_YELLOW);
        break;
      case LANE2_YELLOW:
        if (now - lastStateChange >= 3000) changeState(LANE1_GREEN);
        break;
    }
  }

  // Serial monitor time updates every second
  if (now - lastSerialUpdate >= 1000) {
    lastSerialUpdate = now;
    unsigned long elapsed = (now - lastStateChange) / 1000;
    Serial.print("Current State: ");
    printStateName(currentState);
    Serial.print(" | Time Elapsed: ");
    Serial.print(elapsed);
    if (emergencyMode) Serial.print(" (EMERGENCY)");
    Serial.println("s");
  }
}

void changeState(TrafficState newState) {
  currentState = newState;
  lastStateChange = millis();
  Serial.print(">> Transition to: ");
  printStateName(currentState);
  Serial.println();
  setLights(currentState);
}

void setLights(TrafficState state) {
  digitalWrite(lane1Red, LOW);
  digitalWrite(lane1Yellow, LOW);
  digitalWrite(lane1Green, LOW);
  digitalWrite(lane2Red, LOW);
  digitalWrite(lane2Yellow, LOW);
  digitalWrite(lane2Green, LOW);

  switch (state) {
    case LANE1_GREEN:
      digitalWrite(lane1Green, HIGH);
      digitalWrite(lane2Red, HIGH);
      break;
    case LANE1_YELLOW:
      digitalWrite(lane1Yellow, HIGH);
      digitalWrite(lane2Red, HIGH);
      break;
    case LANE2_GREEN:
      digitalWrite(lane2Green, HIGH);
      digitalWrite(lane1Red, HIGH);
      break;
    case LANE2_YELLOW:
      digitalWrite(lane2Yellow, HIGH);
      digitalWrite(lane1Red, HIGH);
      break;
  }
}

void printStateName(TrafficState state) {
  switch (state) {
    case LANE1_GREEN:  Serial.print("LANE1_GREEN"); break;
    case LANE1_YELLOW: Serial.print("LANE1_YELLOW"); break;
    case LANE2_GREEN:  Serial.print("LANE2_GREEN"); break;
    case LANE2_YELLOW: Serial.print("LANE2_YELLOW"); break;
  }
}
