require 'socket'
require 'timeout'

# connect to server
count=0

array=[]

10.times do |i|

	puts "GO~~(#{count})"
	array[i] = Thread.new{

		Thread.current[:mycount] = count
		count+=1

		sock = begin
           #Timeout::timeout( 60 ) { TCPSocket.new( 'localhost', 5678 ) }
           Timeout::timeout( 60 ) { TCPSocket.open( '10.105.7.51', 5678 ) }
       	rescue StandardError, RuntimeError => ex
           raise "cannot connect to server: #{ex}"
       	end

		puts "thread(#{array[i]}), socket(#{sock.addr})"
		# send sample messages:

		if(ARGV[0]=="0800")
			sock.write( "0800,5,C,#{i},822,26001234,000822018880001,711-758-902,CMDEND")
		elsif(ARGV[0]=="0820")
			sock.write( "0820,6,C,#{i},20130814113321,822,26001234,000822018880001,CMDEND")
		else	
			sock.write( "0800,5,C,#{i},822,26001234,000822018880001,711-758-902,CMDEND")
		end
		sleep( 2 )

		response = begin
               Timeout::timeout( 180 ) { 
					sock.gets( "CMDEND" ).chomp( "CMDEND" ) 
					#puts "Recv:(#{msg})"
				}
           		rescue StandardError, RuntimeError => ex
               		raise "no response from server: #{ex}"
           		end
		puts "received response: '#{response.split(',')}'"

		sock.close
		puts "closing socket"
	}
end

puts "join Go~~~"
array.each{
	|t| t.join
	puts "count(#{count})"
}

