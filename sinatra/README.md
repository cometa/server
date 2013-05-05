Sample Application Server
------------
A fully functional Sinatra Web application that interacts with device subscribed to a Cometa application.

Installation
------------
The application relies on the Cometa Ruby library in `lib/cometa-ruby.rb`. It doesn't use any database or persistent memory. 

Devices must be known to the application and need to subscribe to it before messages can be exchanged. The `check_device` method must be implemented to authenticate a device. It is currently an empty method. Note: this is not a method to authenticate the device with Cometa, but only with this application server.

Before running the application, change the values for the following variables:

	Cometa.app_name = "YOUR_COMETA_APP_NAME"
	Cometa.app_key = "YOUR_COMETA_APP_KEY"
	Cometa.app_secret = "YOUR_COMETA_APP_SECRET"

Usage
-----
To run the application:

	ruby appserver.rb

The application includes a Web page that is a simple API console to interact with devices at the URI:

	http://[APPLICATION_SERVER_URI]:17017/devconsole

<img src="http://www.cometa.io/images/api-console.png" height="472" width="822">

The API console allows to publish (send) messages to subscribed devices of a registered Cometa application and to receive replies.

Note: a registered Cometa application name and key are needed to use the API console.

Application API
---------------
The application provides the following endpoints:

###Authentication
The authentication endpoint used by a Cometa device to obtain a signed authorization string and to be authenticated by the application server:

	/authenticate?<device_id>&<device_key>&<app_key>&<challenge>

Parameters:

* device\_id - the unique device ID (max 32 characters)
* device\_key - the device authentication key
* app\_key - the application key
* challenge - the authentication challenge 

Successful response:

	{
		"status": "200", 
		"signature": "946604ed1d981eca2879:babc3d687335043f55878b3f1eef94815327d6ad533e7c7f51fb30b8ca4683a1"
	}

###Publishing a message
Send a message to a device:

	POST /send.json?id=<device_id>&<app_key>

Parameters:

* device\_id - the unique device ID (max 32 characters)
* app\_key - the application key

The POST body contains the message. The message can be any type, including binary, providing that is not larger than 64 KB.

Successful response:

A device may respond with a reply message that is returned back in the "reply" attribute of the response hash.

	{
		"status": "200",
		"device" : "40:6c:8f:08:7d:5c",
		"reply" : "{ "temperature" : "75.3","humidity":"35.7"}"
	}

###Device statistics
Get statistics on device usage:

	GET /info.json?id=<app_key>&[<device_id>]

Parameters:

* device\_id - (optional) the unique device ID (max 32 characters)
* app\_key - the application key

Successful response:

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

If a device\_id is not provided, the method provides statistics about the registered application instead.




