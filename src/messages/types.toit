// TODO move all of these to their own message classes?

MSGTYPE-GENERAL-ACK /int ::= 5
MSGTYPE-GENERAL-KEEPALIVE /int ::= 6 // No data needed
MSGTYPE-LIVELINK-START /int ::= 10
MSGTYPE-LIVELINK-OPEN /int ::= 11
MSGTYPE-LIVELINK-CLOSE /int ::= 12
MSGTYPE-LIVELINK-HEARTBEAT /int ::= 13
MSGTYPE-LIVELINK-CONFIGUPDATE /int ::= 14
MSGTYPE-LIVELINK-POSITIONDATA /int ::= 15
MSGTYPE-LIVELINK-DEVICESTATUS /int ::= 16
MSGTYPE-DEVICESERVICE-TXNOW /int ::= 30
MSGTYPE-DEVICESERVICE-GSM-CFUN /int ::= 31
MSGTYPE-DEVICESERVICE-GSM-IMEI /int ::= 32
MSGTYPE-DEVICESERVICE-GSM-ICCID /int ::= 33
MSGTYPE-DEVICESERVICE-DEVICEINFO-STATUS /int ::= 34
MSGTYPE-DEVICESERVICE-DEVICEINFO-ID /int ::= 35
MSGTYPE-DEVICESERVICE-DEVICEINFO-TIME /int ::= 36
MSGTYPE-DEVICESERVICE-DEVICEINFO-LASTPOST /int ::= 37
// TODO 38
MSGTYPE-DEVICESERVICE-GPS-CONTROL /int ::= 39
MSGTYPE-DEVICESERVICE-HAPTICS-CONTROL /int ::= 40
MSGTYPE-DEVICESERVICE-DEVICEINFO-TEMP /int ::= 41
MSGTYPE-DEVICESERVICE-BUZZER-CONTROL /int ::= 42
// todo 43
MSGTYPE-DEVICESERVICE-DEVICEINFO-PRESSURE /int ::= 44

// Screenupdate messages
MSGTYPE-UIUPDATE-START /int ::= 10000
MSGTYPE-UIUPDATE-END /int ::= 11000
MSGTYPE-UIUPDATE-TEXT-PAGE /int ::= 10009
MSGTYPE-UIUPDATE-MENU /int ::= 10010
MSGTYPE-UIUPDATE-BITMAP /int ::= 10011
MSGTYPE-UIUPDATE-CLEAR /int ::= 10014
MSGTYPE-UIEVENT-BUTTON /int ::= 10013
// Not used yet?
//MSGTYPE-UIEVENT-HOME /int ::= 10011