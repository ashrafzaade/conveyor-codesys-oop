// --- Declaration ---
FUNCTION_BLOCK FB_JamConveyor EXTENDS FB_Conveyor
VAR_INPUT
    tJamTimeout : TIME := T#5S;   // Max time without a product while running
END_VAR
VAR_OUTPUT
    bJam : BOOL;                  // TRUE when a jam has been detected
END_VAR
VAR
    tonJam : TON;                 // Timer for jam detection
END_VAR


// --- Implementation ---
// Run the base class logic first (not called automatically in CODESYS)
SUPER^();

// Jam detection: motor running but no product detected for tJamTimeout.
// The timer is reset by every product (rising edge of the sensor).
tonJam(IN := (eState = E_State.RUNNING) AND NOT rtSensor.Q, PT := tJamTimeout);

IF tonJam.Q THEN
    bJam := TRUE;
    eState := E_State.IDLE;   // Stop the conveyor
END_IF


// Status outputs are driven directly from the current state
bBatchDone   := (eState = E_State.BATCH_DONE);
bEStopActive := (eState = E_State.ESTOP);

// Clear the requests: each method call is valid for one cycle only
bStartReq := FALSE;
bStopReq  := FALSE;
bResetReq := FALSE;


// ===== Method: Start =====
METHOD Start
// Override: ignore start requests while a jam is active
IF NOT bJam THEN
    SUPER^.Start();   // Call the base class method
END_IF

// ===== Method: Reset =====
METHOD Reset
// Override: also clear the jam flag, then do the normal reset
bJam := FALSE;
SUPER^.Reset();


