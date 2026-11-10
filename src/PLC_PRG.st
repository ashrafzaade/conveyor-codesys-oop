PROGRAM PLC_PRG
VAR
    // --- Inputs (bound to the visualization) ---
    bStart    : BOOL;           // Start button (NO)
    bStopNC   : BOOL := TRUE;   // Stop button (NC)
    bEStopNC  : BOOL := TRUE;   // Emergency stop (NC)
    bReset    : BOOL;           // Reset button (NO)
    bSensor   : BOOL;           // Sensor of conveyor 1
    bSensor2  : BOOL;           // Sensor of conveyor 2 (test via watch window)

    // --- Outputs of conveyor 1 (bound to the visualization) ---
    bMotor     : BOOL;
    bBatchLamp : BOOL;
    bEStopLamp : BOOL;
    iCount     : INT;

    // --- Edge detectors for the buttons ---
    rtStart   : R_TRIG;
    rtReset   : R_TRIG;

    // --- Two instances: one base type, one derived type ---
    Conv1     : FB_Conveyor;
    Conv2     : FB_JamConveyor := (iTarget := 5);   // different batch size

    // --- Interface references for polymorphic access ---
    aConv     : ARRAY[1..2] OF IConveyor;
    i         : INT;

    // --- Mirror of conveyor 2 outputs, for easy monitoring ---
    bMotor2   : BOOL;
    bJam2     : BOOL;
END_VAR
	


// Edge detection for the buttons
rtStart(CLK := bStart);
rtReset(CLK := bReset);

// Bind interface references to the concrete instances
aConv[1] := Conv1;
aConv[2] := Conv2;

// Polymorphic commands: the loop does not know which type each element is
FOR i := 1 TO 2 DO
    IF rtStart.Q THEN
        aConv[i].Start();
    END_IF
    IF NOT bStopNC THEN
        aConv[i].Stop();
    END_IF
    IF rtReset.Q THEN
        aConv[i].Reset();
    END_IF
END_FOR

// Cyclic execution of each instance
Conv1(bSensor := bSensor,  bEStopNC := bEStopNC);
Conv2(bSensor := bSensor2, bEStopNC := bEStopNC, tJamTimeout := T#5S);

// Map conveyor 1 outputs to the variables used by the visualization
bMotor     := Conv1.bMotor;
bBatchLamp := Conv1.bBatchDone;
bEStopLamp := Conv1.bEStopActive;
iCount     := Conv1.iCount;

// Mirror conveyor 2 outputs
bMotor2 := Conv2.bMotor;
bJam2   := Conv2.bJam;

