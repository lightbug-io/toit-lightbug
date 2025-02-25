import i2c
import gpio
import uart
import io

/*
An interface representing a Lightbug device
*/
interface Device extends Comms:
  // A name identifying the type of device
  name -> string

/*
An interface for communicationg to and from a Lightbug device
*/
interface Comms:
  // Reader reading from the device
  in -> io.Reader
  // Writer writing to the device
  out -> io.Writer