// HEADER types
// Auto generated from https://docs-next.lightbug.io/devices/api/headers
HEADER_MESSAGE_ID /int ::= 1             // ID that can be used by receiver to ACK, and client to track for various responses, or re-sends
HEADER_CLIENT_ID /int ::= 2              // ID of the client sending the message
HEADER_RESPONSE_TO_MESSAGE_ID /int ::= 3 // ID of the message that is being responded to
HEADER_MESSAGE_STATUS /int ::= 4         // Status of the message. If omitted, assume OK?
HEADER_MESSAGE_METHOD /int ::= 5         // Request a service to be perform an action
HEADER_SUBSCRIPTION_INTERVAL /int ::= 6 // Interval in ms for a subscription to be sent
HEADER_FORWARDED_FOR_TYPE /int ::= 9
HEADER_FORWARDED_FOR /int ::= 10         // ID of the client sending the original message that is being forwarded
HEADER_FORWARDED_RSSI /int ::= 11        // RSSI of forwarded message
HEADER_FORWARDED_SNR /int ::= 12         // SNR  of forwarded message
HEADER_FORWARD_TO_TYPE /int ::= 13        // Type  of forwarded message
HEADER_FORWARD_TO /int ::= 14     