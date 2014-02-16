#!/usr/bin/ruby
#
# Written for a Raspberry pi - polling redis for the setting of a specific variable, and then writing out to a Jeenode a set of commands
#
#
require('time')
require 'serialport'
require 'ruby-growl'
require 'redis'


     $debug = false
     $sleeptime = 4  # time to sleep in seconds between full updates.
     $version = "0.2_rpi";
     $destination_jeenode = "49"
     
#params for serial port
     port_str = "/dev/ttyAMA0"  #differs depending on your setup
     baud_rate = 57600
     data_bits = 8
     stop_bits = 1
     parity = SerialPort::NONE

@node_list = ["35","43"]




def check_for_priority_messages
  #
  # Check to see if there are any new priority messages queued for any display
  # Early version checks for a variable in memcached, and sets it to "" as soon as it has ben picked up
  #
#  @message = $store.fetch_key("Priority message")
#  @message = $redis.exists("Stair movement")
  if ($redis.exists("Stair movement")) then
#    send_prowl(@message)
  begin
    $sp.write "10, 49 s" + '\r' # Send code to turn on the LED strip with settings 10
    puts Time.now
    sleep(0.25)
    $sp.write "10, 49 s" + '\r' # Send code to turn on the LED strip with settings 10
    sleep(0.25) 
    puts "Found priority message"   
      $redis.del("Stair movement")
      rescue Exception => e  
        puts "Exception occured - message is :"
        puts e.message  
        puts e.backtrace.inspect  
         puts "Something went wrong in main loop - restarting"
       end     
  end
end




      $sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
      $redis = Redis.new(:host => "192.168.0.17", :port => 6379) 
      puts "Waiting for sending node to bootstrap"
      sleep(15)
      $sp.write "\r"
      
    while true
      check_for_priority_messages()
        $time = Time.now
        timestring = $time.strftime("%Y-%m-%d %H:%M:%S")
                inn = $sp.gets
                hum_array = inn.strip.split(' ')
				if hum_array.size == 6 then
					if hum_array[0] == "OK" then               
						puts timestring + "," + inn.strip
					end
				end
        movement_indicator = hum_array[3].to_i - ((hum_array[3].to_i >> 1) * 2)
	if @node_list.include?(hum_array[1]) then
        if movement_indicator != 0 then
          movement_detected = true
          puts "***** Movement detected"          
		  $redis.set("Stair movement",timestring)
        else
          movement_detected = false
        end
#      sleep(0.5)
	end      
    end
