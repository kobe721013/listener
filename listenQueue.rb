#try to use queue
require 'socket'
require 'logger'

portNumber=5678
datetime_format="%Y/%m/%d_%H:%M:%S"
#time=Time.new.strftime("%Y%m%d")
#logFileName=time+".log"
server = TCPServer.new portNumber
#puts "listening....."
logger = Logger.new(Time.new.strftime("%Y%m%d")+".log")
logger.datetime_format=datetime_format
logger.info("(#{__FILE__},#{__LINE__})"){"start listening..."}
logger.close


count=0
loop do
	#Thread.start(server.accept) do |client|
		
		client=server.accept
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
                        
                        
            msg="0810,(#{para[1]}),4,#{t.strftime("%Y/%m/%d-%H:%M:%S")},zeyang,zeyang,/home/TMS/999/Param/0101203709/18400030/,CMDEND"
            client.puts msg
			
            
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
