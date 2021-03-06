#
# Cometa is a cloud infrastructure for embedded systems and connected 
# devices developed by Visible Energy, Inc.
#
# Copyright (C) 2013, Visible Energy, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# ruby appserver.rb
#
# A sample application server to interact with devices through the Cometa server.
# 
# The application must be registered with the Cometa server and have proper credentials.
#
require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'sinatra-websocket'
require 'thread'

# https://github.com/simulacre/sinatra-websocket

# Cometa Ruby server library
require './lib/cometa-ruby.rb'

#
# Change the values with the registered application name and credentials:
#
#Cometa.app_name = "YOUR_COMETA_APP_NAME"
#Cometa.app_key = "YOUR_COMETA_APP_KEY"
#Cometa.app_secret = "YOUR_COMETA_APP_SECRET"
#Cometa.app_name = "cometatest"
#Cometa.app_key = "946604ed1d981eca2879"
#Cometa.app_secret = "ea724dc4811d50768084"
Cometa.app_name = "cloudfridge"
Cometa.app_key = "5465b57fdeb0d16712d6"
Cometa.app_secret = "aa375b970d037fb0fb2e"

#
# Check if a device is authorized to use the application.
#
# In a real application this would probably be a class method, possibly
# checking a database for a match and would also verify that a device is 
# provisioned and enabled to use the service.
#
def check_device(device_id, device_key)
    return true     # today every device gets in
end

# ------------------------------------------------------------------------

set :server, %w[thin]
set :port, 7017

# needed to avoid CORS warnings from Rack 
set :protection, :except => [:http_origin]

puts "Application " + Cometa.app_name + " connected to Cometa server."

# used to synchronize the websockets server with the upload requests
mutex = Mutex.new
cv = ConditionVariable.new
@@message
set :sockets, []



get '/' do
  if !request.websocket?
    status(404)
    content_type('application/json')
    return {:status => 404, :error => "Endpoint not in the API."}.to_json
  else
    request.websocket do |ws|
      ws.onopen do
        #cv = ConditionVariable.new  
        settings.sockets << ws  
        while true
        mutex.synchronize {
            # wait for a message to be received from a device
            cv.wait(mutex)
            # the message is in the global variable
            puts "Websockets: sending the message: " + @@message
            EM.next_tick { settings.sockets.each{|s| s.send(@@message) } }
        }
        end
      end
#      ws.onmessage do |msg|
#        EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
#      end
      ws.onclose do
        settings.sockets.delete(ws)  
        warn("wetbsocket closed")
      end
    end
  end
end

#
# Webhook to receive a POST when upstream messages (HTTP chunks) are sent by a device
#
post "/upload" do
    mutex.synchronize {
        ## move the message in the request into a global variable
        @@message = request.env["rack.input"].read
        # signal the websockets thread that a message is available
        cv.signal
    }
end

#
# An application server must implement a GET method to be used within the device
# Cometa authentication handshake and the method's name must be known to the device.
#
# GET /authenticate?<device_id>&<device_key>&<app_key>&<challenge> 
#
# The method's name is arbitrary but the method has to have the four parameters: 
# <device_id>, <device_key>, <app_key>, <challenge>.
#
# The <challenge> parameter is a JSON object received by the device from the
# Cometa server as result of the initial subcribe request.
# 
# This method must return a JSON object with a response code and a signature 
# attribute for the device to complete the authentication process with a Cometa
# server.
#
# It is also an opportunity for the application server to validate
# the device using the supplied device_key (which is not checked elsewhere).
# Return a response other than 200 to prevent a device to authenticate for 
# reasons other than a wrong signature.
#
get "/authenticate" do
    # check mandatory parameters
    if params[:device_id].nil? || params[:device_key].nil? || params[:app_key].nil? || params[:challenge].nil? || params[:challenge] == ""
        status(400)
        content_type('application/json')
        return {:response => 400, :error => "Parameter missing."}.to_json    
    end
    
    # check if the application key provided matches
    if params[:app_key] != Cometa.app_key
        status(400)
        content_type('application/json')
        return {:response => 400, :error => "Application key mismatch."}.to_json    
    end       
    
    # check if the device is authorized to use this application
    if !check_device(params[:device_id], params[:device_key])
        status(403)
        content_type('application/json')
        return {:response => 403, :error => "Device is forbidden."}.to_json
    end

puts params
#return {:response => 403, :error => "Debugging."}.to_json
    
    # use the helper to get a signature for the provided challenge
    signature = Cometa.signature(params[:challenge])
    
    # return a JSON object to the device
    puts signature.to_json
    status(200)
    content_type('application/json')
    return {:response => 200, :signature => signature }.to_json
end

#
# POST /send.json?id=<device_id>&<app_key>
#
# Send a message in the body of the request to the specified device.
#
post "/send.json" do    
    # check parameters 
    if params[:device_id].nil? || params[:app_key].nil?
        status(400)
        content_type('application/json')
        return {:status => 400, :error => "Parameter missing." }.to_json    
    end
    # check if the application key provided matches
    if params[:app_key] != Cometa.app_key
        status(400)
        content_type('application/json')
        return {:response => 400, :error => "Application key mismatch."}.to_json    
    end 
    
    if !request.env["CONTENT_TYPE"].nil?
        # For documentation:
        #
        # Content-Type == "x-www-form-urlencoded" is for a form (but not necessarily)
        # passing the message unchanged to be published
    end
    
    begin
        # use the helper to publish the message
        reply = Cometa.publish(params[:device_id], request.body.read)
    rescue
        # timeout or network error
        status(408)
        content_type('application/json')
        return {:status => 408, :error => "Cometa server timeout." }.to_json
    end
    puts "DEBUG: response from Cometa: " + reply
    
    status(200)
    headers 'Access-Control-Allow-Origin' => "*"
    content_type('application/json')
    return reply
end

#
# GET /info.json?id=<app_key>&[<device_id>]
#
# Get information and stats for the specified device.
#
get "/info.json" do
    # check parameters 
    if params[:app_key].nil?
        status(400)
        content_type('application/json')
        return {:status => 400, :error => "Parameter missing." }.to_json    
    end
    # check if the application key provided matches
    if params[:app_key] != Cometa.app_key
        status(400)
        content_type('application/json')
        return {:response => 400, :error => "Application key mismatch."}.to_json    
    end 
    
    begin
        # use the helper to get info
        reply = Cometa.info(params[:device_id])
    rescue
        # timeout or network error
        status(408)
        content_type('application/json')
        return {:status => 408, :error => "Cometa server timeout." }.to_json
    end 
    
    status(200)
    content_type('application/json')
    return reply
end

#
# Return the views/devconsole.erb template with an API console for testing
#
get "/devconsole" do
    @app_name = Cometa.app_name
    @app_key = Cometa.app_key
    @http_host = request.env['HTTP_HOST']
    
    erb :devconsole
end

#
# Not found endpoints.
#
not_found do
  status(404)
  content_type('application/json')
  return {:status => 404, :error => "Endpoint not in the API."}.to_json
end
