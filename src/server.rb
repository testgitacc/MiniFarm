require 'data_mapper'
#require 'socket'

DataMapper::Logger.new($stdout, :debug)
# A MySQL connection:
DataMapper.setup(:default, 'mysql://user:pass@localhost/minifarm')
# A Postgres connection:
#DataMapper.setup(:default, 'postgres://user:pass@localhost/minifarm')

class Plant
  include DataMapper::Resource

  property :id, Serial   
  property :type, String    
  property :stage, Integer
  property :x, Integer
  property :y, Integer
end

DataMapper.finalize

#require  'dm-migrations'
#DataMapper.auto_upgrade!


socket_server = TCPServer.open(11843)
 
def get_field
  res="<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  res+="<field>"
  Plant.all.each { |plant|
    res+="<#{plant.type} id=\"#{plant.id}\" x=\"#{plant.x}\" y=\"#{plant.y}\" stage=\"#{plant.stage}\" />"
  }
  res+="</field>\0"
end

def new_plant(str)
  md=str.match(/<(\w+) x=\"(\d+)\" y=\"(\d+)\"/)
  if md
    Plant.create(:type=>md[1],:x=>md[2],:y=>md[3],:stage=>1)
  end
end

def grow_up
  Plant.all.each { |plant|
    plant.stage+=1
    if plant.stage>5
      plant.destroy
    else
      plant.save
    end
  }
end

puts "Starting the socket server"
 
while true
    Thread.new(socket_server.accept) do |connection|
 
        puts "Accepting connection from: #{connection.peeraddr[2]}"
 
        begin
            while connection
                incoming_data = connection.gets("\0")
                if incoming_data != nil
                    incoming_data = incoming_data.strip
                end
 
                puts "Incoming: #{incoming_data}"
 
                if incoming_data == "DISCONNECT"
                    puts "Received: DISCONNECT, closed connection"
                    connection.close
                    break
                elsif incoming_data == "GET_FIELD"
                    puts "Sending field..."
                    connection.puts(get_field)
                    connection.flush
                elsif incoming_data == "GROW_UP"
                    puts "Growing up..."
                    grow_up
                    connection.puts(get_field)
                    connection.flush
                elsif incoming_data.match("<newPlant>")
                    puts "New plant"
                    new_plant(incoming_data)
                    connection.puts(get_field)
                    connection.flush
                elsif incoming_data == "HARVEST"
                    puts "Harvest"
                    connection.puts(get_field)
                    connection.flush
                else
                    connection.puts "You said: #{incoming_data}\0"
                    connection.flush
                end
            end
        rescue Exception => e
          puts "#{ e } (#{ e.class })"
        ensure
          connection.close
          puts "ensure: Closing"
        end
    end
end
