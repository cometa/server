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
# cometa-ruby.rb - Ruby support library for Cometa Application Server
#
# The Cometa class implements some helpers for interacting with the 
# Cometa service.
#

require 'socket'
require 'openssl'
require 'net/http'

COMETA_HOSTNAME = "api.cometa.io"
COMETA_PORT = 7007

@@cometa_sock
@@app_name
@@app_key
@@app_secret
    
class Cometa
    #
    # Class initializer.
    #
    # Connect to the Cometa server and initialize a socket.
    #
    @@cometa_sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
    addr_info = Addrinfo.getaddrinfo(COMETA_HOSTNAME, COMETA_PORT, :INET, :STREAM)
    count = 0
    # addr_info contains an address list 
    addr_info.each do |addr|
        # puts "DEBUG: trying to connect to : " + addr.ip_address
        begin
            @@cometa_sock.connect(addr)
            break
        rescue
            count += 1
        end
    end
    if count == addr_info.length
       # failed to resolve COMETA_HOST
       abort "Failed to resolve " + COMETA_HOSTNAME + ". Exiting ..."
    end
    
    #
    # Setters and getters for class globals.
    #
    def self.app_name=(name)
        @@app_name = name
    end
    
    def self.app_key=(key)
        @@app_key = key
    end
    
    def self.app_secret=(secret)
        @@app_secret = secret
    end

    def self.app_name
        @@app_name
    end
    
    def self.app_key
        @@app_key
    end

    #
    # Helper for generating a Cometa authentication signature from a 
    # received challenge and the application secret.
    #
    def self.signature(challenge)
         # extract the challenge attribute from the received object
        challenge = JSON.parse(challenge)
        
        # use the "connection_id" in the provided challenge to generate a signature
        signature = OpenSSL::HMAC.hexdigest('sha256', @@app_secret, challenge["connection_id"])
        
        # add the application key and a separator
        signature = @@app_key + ":" + signature
        puts "DEBUG: challenge: " + challenge["connection_id"] + " signature: " + signature
        
        signature
    end
  
    def self.publish(device_id, message)
        cmd = "/publish?device_id=#{device_id}&app_name=#{@@app_name}&app_key=#{@@app_key}" 
        # create a signature for the command
        auth = OpenSSL::HMAC.hexdigest('sha256', @@app_secret, cmd)
        cmd += "&auth_signature=" + auth
            
        uri = URI.parse("http://" + COMETA_HOSTNAME + ":" + COMETA_PORT.to_s + cmd)
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = message
        request["Content-Type"]="application/json"
        http = Net::HTTP.new(uri.host, uri.port)

        reply = http.request(request)

        # the Cometa server returns a JSON object such as:
        # { "status": "200", "device": "S100", "reply": "XXXXXX" }
        # puts "DEBUG: response from Cometa: " + reply.body
        
        reply.body
    end
    
    def self.info(device_id)
        if device_id.nil?
            cmd = "/info?app_name=#{@@app_name}&app_key=#{@@app_key}" 
            # create a signature for the command
            auth = OpenSSL::HMAC.hexdigest('sha256', @@app_secret, cmd)
            cmd += "&auth_signature=" + auth
        else
            cmd = "/info?device_id=#{device_id}&app_name=#{@@app_name}&app_key=#{@@app_key}" 
            # create a signature for the command
            auth = OpenSSL::HMAC.hexdigest('sha256', @@app_secret, cmd)
            cmd += "&auth_signature=" + auth
        end    
        uri = URI.parse("http://" + COMETA_HOSTNAME + ":" + COMETA_PORT.to_s + cmd)
        request = Net::HTTP::Get.new(uri.request_uri)
        request["Content-Type"]="application/json"
        http = Net::HTTP.new(uri.host, uri.port)

        reply = http.request(request)
        
        reply.body
    end
  
end