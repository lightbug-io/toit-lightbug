import system

// Simple memory monitoring utility for development
print-memory-task
    --heap/bool=true
    --objects/bool=true
    --interval/Duration=(Duration --ms=10000):
  task:: while true:
    if heap: system.serial-print-heap-report
    if objects: system.print_objects
    sleep interval