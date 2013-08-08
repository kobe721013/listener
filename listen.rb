#try to use multi-thread to access data
require 'socket'
require 'logger'
require 'mysql'

portNumber=5678
datetime_format="%Y/%m/%d(%H:%M:%S)"
server = TCPServer.new portNumber
logger = Logger.new(Time.new.strftime("%Y%m%d")+".log")
logger.datetime_format=datetime_format
logger.info("(#{__FILE__},#{__LINE__})"){"start listening..."}
logger.close




queue = Queue.new

threadMySQL=Thread.new{
	puts "new thread for MySQL OK"
	loop do
		begin 
			unless(queue.empty?())
				con = Mysql.new 'localhost', 'root', '123456', 'Listen'	
				loop do
					unless queue.empty?()
			
						rs=con.query(queue.pop)
						sleep(0.5)
					end
				end
		
			end
		rescue Mysql::Error => e
      		puts e.errno
      		puts e.error
  
  		ensure
      		con.close if con
  		end
	end
	puts "loop finish"
}

threadMySQL.run


loop do
	Thread.start(server.accept) do |client|
		
		begin        
			# create logger
			#file = File.open(logFileName, File::WRONLY | File::APPEND | File::CREAT)
			
			t=Time.new
			nowTime=t.strftime("%Y%m%d")
			logFileName=nowTime+".log"
			
			logger = Logger.new(logFileName)
			logger.datetime_format=datetime_format
			
			puts "recv from: #{client.peeraddr[2]}"
            puts "hostAddr:(#{client.addr[2]})"
            #puts "client class(#{client.class})"
            #msg = client.recv(1024)
			msg=client.gets("CMDEND")
			
			#logger.info("(#{__FILE__},#{__LINE__})"){"---------------------------"}
			logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]in:(#{msg})"}
                        
			para = msg.split(',')
                        
                        
            msg="0810,#{para[1]},4,#{t.strftime("%Y/%m/%d-%H:%M:%S")},zeyang,zeyang,/home/TMS/999/Param/0101203709/18400030/,CMDEND"
            client.puts msg

			queue << "insert into event (DateTime,Success,Bank_ID,TID,MID,SN) values('#{t.strftime("%Y%m%d%H%M%S")}',0,822,'26001818','000822018880001','111-222-333')"
			
			puts "queue.ize(#{queue.size})"           
 
			logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]out:(#{msg})"}
			#logger.info("(#{__FILE__},#{__LINE__})"){"***************************"}
		rescue Exception => e
            # Displays Error Message
            logger.error("(#{__FILE__},#{__LINE__})"){"#{ e } (#{ e.class })"}
            puts "#{ e } (#{ e.class })"
        ensure
            client.close
            puts "ensure: Closing"
			sleep (1)
			logger.close
        end
	end
end

