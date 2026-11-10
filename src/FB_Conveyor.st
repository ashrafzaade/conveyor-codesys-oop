// --- Declaration ---
FUNCTION_BLOCK FB_Conveyor IMPLEMENTS IConveyor
VAR_INPUT
    bSensor   : BOOL;           // Product detection sensor
    bEStopNC  : BOOL := TRUE;   // Emergency stop (NC: TRUE in normal condition)
    iTarget   : INT := 10;      // Target count per batch
END_VAR
VAR_OUTPUT
    bMotor       : BOOL;        // Conveyor motor
    bBatchDone   : BOOL;        // TRUE when the batch is complete
    bEStopActive : BOOL;        // TRUE while in emergency stop state
    iCount       : INT;         // Product counter
END_VAR
VAR
    eState    : E_State := E_State.IDLE;   // Current machine state
    rtSensor  : R_TRIG;                    // Rising edge detector for the sensor

    // Command requests, set by the methods and cleared at the end of each cycle
    bStartReq : BOOL;
    bStopReq  : BOOL;
    bResetReq : BOOL;
END_VAR


// --- Implementation ---
// Detect rising edge of the sensor (one pulse per product)
rtSensor(CLK := bSensor);

// E-Stop has priority over everything, in every state
IF NOT bEStopNC THEN
    eState := E_State.ESTOP;
END_IF

CASE eState OF

    E_State.IDLE:
        bMotor := FALSE;
        // Start is ignored if a stop request arrives in the same cycle
        IF bStartReq AND NOT bStopReq THEN
            iCount := 0;
            eState := E_State.RUNNING;
        END_IF

    E_State.RUNNING:
        bMotor := TRUE;
        IF rtSensor.Q THEN
            iCount := iCount + 1;
        END_IF
        IF bStopReq THEN
            // Normal stop: back to idle
            eState := E_State.IDLE;
        ELSIF iCount >= iTarget THEN
            // Batch finished
            eState := E_State.BATCH_DONE;
        END_IF

    E_State.BATCH_DONE:
        bMotor := FALSE;
        IF bResetReq THEN
            iCount := 0;
            eState := E_State.IDLE;
        END_IF

    E_State.ESTOP:
        bMotor := FALSE;
        // E-Stop must be released AND a reset request is required
        IF bEStopNC AND bResetReq THEN
            iCount := 0;
            eState := E_State.IDLE;
        END_IF

END_CASE


// Status outputs are driven directly from the current state
bBatchDone   := (eState = E_State.BATCH_DONE);
bEStopActive := (eState = E_State.ESTOP);

// Clear the requests: each method call is valid for one cycle only
bStartReq := FALSE;
bStopReq  := FALSE;
bResetReq := FALSE;


// ===== Method: Start =====
METHOD Start
// Request a start (valid for one cycle)
bStartReq := TRUE;

// ===== Method: Stop =====
METHOD Stop
// Request a normal stop (valid for one cycle)
bStopReq := TRUE;

// ===== Method: Reset =====
METHOD Reset
// Request a reset after batch complete or emergency stop (valid for one cycle)
bResetReq := TRUE;


