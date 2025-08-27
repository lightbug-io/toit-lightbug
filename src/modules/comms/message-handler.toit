import ...protocol as protocol

/**
 * Interface for message handlers in the comms system.
 * 
 * Message handlers can be registered with the comms system to automatically
 * process specific message types.
 */
interface MessageHandler:
  /**
   * Handle a received message.
   * 
   * @param msg The received message
   * @returns true if the message was handled, false if it should be processed normally
   */
  handle-message msg/protocol.Message -> bool
