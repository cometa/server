Cometa
======
###A hosted API for easily and securely enable two-way, real-time interactions to connected devices.

[www.cometa.io](http://www.cometa.io)

Cometa is an edge server that maintains long-lived, bi-directional HTTP(S) connections to remote devices with a simple publish-subscribe interaction pattern. It offers a hosted API at api.cometa.io that is used by both the software in a device and in the application server that intends to communicate with the device.

A device that "subscribes" to a registered Cometa application allows the associated application server to securely send messages "published" to the device's unique ID communication channel. A message received by the device results in a action by the device and in a response message, that is sent back to the Cometa server and relayed to the application server in a synchronous HTTP operation. This way Cometa delivers low-latency, one-to-one messages between your application server and enabled devices regardless of NAT and firewalls.

This repository contains libraries to develop Web applications that use the Cometa API and full examples. 

*Note: the Cometa server and hosted API service is currently in private beta.*
Synopsis
--------
Cometa can deliver a message from an application to a remote device behind a NAT at any time, not only in response to an HTTP request. The data is delivered over a single, long-lived connection, opened when an authorized device subscribes to Cometa.

The following diagram shows the simple *publish-subscribe* interaction model of Cometa with devices and the publishing application server:

![Interaction](http://www.websequencediagrams.com/cgi-bin/cdraw?lz=CnBhcnRpY2lwYW50IERldmljZQAGDVdlYkFwcGxpY2F0aW9uACENQ29tZXRhCgAvBi0-AAkGOiBTdWJzY3JpYmUKbm90ZSByaWdodCBvZgA6ECAgICBTZXJ2ZXIgaGFzIG1lc3NhZ2UgZm9yAIB_CGVuZCBub3RlCgB2DgBgClB1Ymxpc2ggKAA2BykKAIENBi0-AIFDBjoADwsAfg4AgWIHICAgIFByb2NlcwB4CQBsCgCBSBAocmVzcG9ucwBcCwCCDw4AFg0AgVAsAFEIIGZyb20AgW0R&s=napkin)

Getting Started
---------------
To get started with developing a Web application that can establish 2-way, secure connections with remote devices, have a look at language-specific libraries and the full examples in this repository.