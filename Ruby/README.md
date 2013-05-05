Ruby Library
------------
This library implements a Cometa Ruby class that is an abstraction of the publishing hosted API and simplifies its use in an application server.

Usage
-----

###Initialization
Initialize the Cometa service with global class instances:

	Cometa.app_name = "your_application_name"
	Cometa.app_key = "your_application_key"
	Cometa.app_secret = "your_secret"

Interacting with the Cometa hosted API
---
###Publish a message
Use the class method `publish`:

	reply = Cometa.publish(device_id, message)

Parameters:

* device_id - the unique device ID (max 32 characters)
* message - the message to send the device

Response:

* reply - the device response

###Get device info
Use the class method `info`:

	reply = Cometa.info(device_id)

Parameters:

* device_id - the unique device ID (max 32 characters)

Response:

	{
	    "status": "200", 
	    "device": "40:6c:8f:08:7d:5c", 
	    "ip_address": "54.241.16.45", 
	    "heartbeat": "1367769699", 
	    "info": "linux_client", 
	    "stats": {
	        "connected_at": "1367596124", 
	        "messages": "4007", 
	        "bytes_up": "5003423", 
	        "bytes_down": "20023", 
	        "latency": "32"
	    }
	}

###Authorization signature for device challenge
Use the class method `signature` to generate a HMAC-SHA256 signature of the challenge, as expected by the Cometa server:

		auth_string = Cometa.signature(challenge)

Parameters:

* challenge - the challenge as received from the device

Response:

* the authorization signature

