// An example showing that uncaught exceptions in tasks will bubble up
// and terminate the entire program, including other tasks.
//
// [jaguar] INFO: program 916713fb-907a-7a41-2850-ea5a0e1fd494 started
// Looping...
// Task2 is running...
// Looping...
// Task2 is running...
// Looping...
// Looping...
// Task2 is running...
// Looping...

// ******************************************************************************
// EXCEPTION error.
// Task1 failed after 5 loops
//   0: main.<lambda>             examples/toit/task_failures.toit:8:5
// ******************************************************************************

// [jaguar] ERROR: program 916713fb-907a-7a41-2850-ea5a0e1fd494 stopped - exit code 1

main:
  // Task 1 will loop 5 times and then throw an error, demonstrating task failure handling.
  task --name="task1" ::
    5.repeat:
      print "Looping..."
      sleep (Duration --s=1)
    throw "Task1 failed after 5 loops"
  
  // Task 2 will try to run forever
  task --name="task2" ::
    while true:
      print "Task2 is running..."
      sleep (Duration --s=2)
  
  // There is no other code here, so the main task will just wait for the others to run.
  // However, when task1 fails, the exception will bubble all the way up and
  // terminate the entire program, including task2.
