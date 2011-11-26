# ArduinoRestGateway Dev Notes

**public_server API:**
- must include a register\_controller() method, which is called by the controller to register itself
- must include a respond() method that accepts a response (string) and an id (int) that identifies the client

**controller API:** 
- must include a register\_request method, which is called by the public\_server when a request is received. This method must accept a request (string) and an id (int) that identifies the client


**NEXT STEPS:**
- create the data structures that will be used to hold the resource devices, resource services and resource relationships 
- create code that automatically updates these data structures by making a request to all registered arduino addresses
- develop code that parses and routes requests based on the data structures listed above