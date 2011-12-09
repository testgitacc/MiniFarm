require 'rubygems'
require 'pg'
require 'socket'

#DataMapper::Logger.new($stdout, :debug)
# A MySQL connection:
#DataMapper.setup(:default, 'mysql://user:pass@localhost/minifarm')
# A Postgres connection:
#DataMapper.setup(:default, 'postgres://user:pass@localhost/minifarm')



#@client=Mysql2::Client.new(:host => "localhost", :username => "user",:password=>"pass", :database=>"minifarm")
@pg = PGconn.connect( :host => "localhost", :user => "user",:password=>"pass", :dbname=>"minifarm")
@pg.exec("CREATE TABLE IF NOT EXISTS plants 
(
  id serial NOT NULL,
  \"type\" character varying(30),
  stage integer,
  x integer,
  y integer,
  CONSTRAINT id PRIMARY KEY (id)
)")

#class Plant
#  include DataMapper::Resource
#
#  property :id, Serial   
#  property :type, String    
#  property :stage, Integer
#  property :x, Integer
#  property :y, Integer
#end
#
#DataMapper.finalize

#require  'dm-migrations'
#DataMapper.auto_upgrade!


socket_server = TCPServer.open(11843)
 
def get_field
  res="<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  res+="<field>"
   @pg.exec("select id, type, x, y, stage from plants").each { |plant|
    p plant
    res+="<#{plant["type"]} id=\"#{plant["id"]}\" x=\"#{plant["x"]}\" y=\"#{plant["y"]}\" stage=\"#{plant["stage"]}\" />"
  }
  res+="</field>\0"
end

def new_plant(str)
  md=str.match(/<(\w+) x=\"(\d+)\" y=\"(\d+)\"/)
  if md
    #Plant.create(:type=>md[1],:x=>md[2],:y=>md[3],:stage=>1)
     @pg.exec("insert into plants (\"type\",x,y,stage) values ('#{md[1]}','#{md[2]}','#{md[3]}','1')")
  end
end

def harvest_plant(str)
  md=str.match(/<harvestPlant id=\"(\d+)\" \/>/)
  if md
     @pg.exec("delete from plants where id=#{md[1]}")
  end
end

def grow_up
   @pg.exec("select id,stage from plants").each { |plant|
     p plant
     stage=plant["stage"].to_i+1
    if stage>5
       @pg.exec("delete from plants where id=#{plant["id"]}")
    else
       @pg.exec("update plants set stage=stage+1 where id=#{plant["id"]}")
    end
  }
end

def socket_policy
  '<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
   <allow-access-from domain="*" to-ports="*" />
</cross-domain-policy>'+"\0"
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
                  elsif incoming_data.include? "newPlant"
                      puts "New plant"
                      new_plant(incoming_data)
                      connection.puts(get_field)
                      connection.flush
                  elsif incoming_data.include? "harvestPlant"
                      puts "Harvest"
                      harvest_plant(incoming_data)
                      connection.puts(get_field)
                      connection.flush
                  elsif incoming_data == "<policy-file-request/>"
                      puts "socket_policy"
                      connection.puts(socket_policy)
                      connection.flush
                      connection.close
                      break
                  else
                      connection.puts "You said: #{incoming_data}\0"
                      connection.flush
                  end
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
