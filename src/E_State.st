TYPE E_State :
(
    IDLE       := 0,   // Waiting for start command
    RUNNING    := 1,   // Conveyor running, counting products
    BATCH_DONE := 2,   // Target count reached, waiting for reset
    ESTOP      := 3    // Emergency stop active, latched until reset
);
END_TYPE