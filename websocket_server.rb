require 'eventmachine'
require 'em-websocket'
require 'json'

@names = []
@clients = {}

EventMachine.run do
	EventMachine::WebSocket.start(:host => '0.0.0.0',:port => 8080) do |socket|
		socket.onopen do
			puts "[CONNECTION]"
			json = JSON.parse "{}"
			json['type'] = "message"
			json['data'] = "Welcome!"
			json['name'] = "Server"
			socket.send json.to_json
		end

		socket.onmessage do |msg|
			json = JSON.parse msg

			# Check the type of the message
			# If it is just a message we resend it to all the clients
			if json["type"].eql? 'message'
				if @names.index json["name"]
					@clients.keys.each do |client|
						@clients[client].send json.to_json
					end
				end
			# If it is a name the message is a "request" to join.
			# If the username is not dup we insert it in the names and clients array
			# and send the new user list to the clients.
			elsif json["type"].eql? 'name'
				if !@names.index json["name"]
					@names << json["name"]
					@clients[json["name"]] = socket
					json = {}
					json["type"] = "names"
					json["data"] = @names
					@clients.keys.each do |client|
						@clients[client].send json.to_json
					end
				else
					json = {}
					json["type"] = "names"
					json["data"] = false
					socket.send json.to_json
				end
			end
		end

		socket.onerror do |error|
			puts "[ERROR] #{error.message}"
			puts "[ERROR] #{error.inspect}"
		end

		# When a client disconnects we delete it from names and clients list.
		socket.onclose do
			name = ""
			@clients.keys.each do |key|
				if @clients[key].eql? socket
					name = key
					break
				end
			end
			@names.delete name
			@clients.delete name
		end
	end
end