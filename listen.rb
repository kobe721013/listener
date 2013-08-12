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

#==========================================================
# Notes by kobe
# get table bank, edc logon request needed FTP server 
# account and pwd to download config or ap
#==========================================================
#get database table bank
bankData=[]
begin
	con = Mysql.new 'localhost', 'root', '123456', 'Listen'
	rs=con.query("Select * from bank")

	rs.each_hash do |row|
	bankData << row
	end
rescue MySql::Error => e
    puts e.errno
    puts e.error
ensure
 	con.close if con
end

#--------------------------------------------------------------

#==========================================================
# multi-thread to receive logon request and
# puts sql commamd into queue
# new another thread to process all sql commamd of queue
#==========================================================
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
#----------------------------------------------------------

#==========================================================
# multi-thread to receive logon request and
# puts log into queue
# new another thread to process all log of queue
#==========================================================
logQueue = Queue.new
threadLog=Thread.new{
	puts "new thread for log OK"
	loop do
		begin 
			unless(logQueue.empty?())
				#con = Mysql.new 'localhost', 'root', '123456', 'Listen'	
				t=Time.new
				nowTime=t.strftime("%Y%m%d")
				logFileName=nowTime+".log"
				logger = Logger.new(logFileName)

				loop do
					unless logQueue.empty?()
						puts "get log"
						logger.info(logQueue.pop)
						sleep(0.5)
					end
				end
		
			end
		rescue Exception => e
  			logger.error("(#{__FILE__},#{__LINE__})"){"#{ e } (#{ e.class })"}
  		ensure
			logger.close if logger
			sleep(0.5)      		
  		end
	end
}
threadLog.run
#----------------------------------------------------------


logonReq={	:cmdType=>0, 
			:fieldCnt=>1, 
			:dlType=>2, 
			:traceNum=>3,
			:bankID=>4,
			:TID=>5,
			:MID=>6,
			:SN=>7,
			:CMDEND=>8}

rootDirectory="/home"

loop do
	Thread.start(server.accept) do |client|
	#client=server.accept	
		begin        
			# create logger
			#puts "from #{client.peeraddr}"	
			
			t=Time.new
			nowTime=t.strftime("%Y%m%d%H%M%S")
			
			msg=client.gets("CMDEND")#CMDEND
			#logger.info("(#{__FILE__},#{__LINE__})"){"---------------------------"}
			#logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]in:(#{msg})"}
			logQueue << "(#{__FILE__},#{__LINE__})(#{client.peeraddr}) in:(#{msg})"            
            
			para = msg.split(',')
			
			if(para[0] == "0800")
			
				#check Bank_ID existed or not in database
				bankRow=bankData.select{|row| row["Bank_ID"].to_i==para[logonReq[:bankID]].to_i}
				
				response = case
					when para.length != logonReq.length 
						then "0810,1,e1:logon parameter count was #{para.length} spec. total count was #{logonReq.length},CMDEND"
					when (para[logonReq[:dlType]] != "C" and para[logonReq[:dlType]] != "A")
						then "0810,1,e2:logon [download type] was not A or C,CMDEND"
					when (bankRow.empty?)
						then "0810,1,e3:logon request Bank ID(#{para[logonReq[:bankID]]}) was not support,CMDEND"
					
					when File.directory?(dlPath="#{rootDirectory}/#{para[logonReq[:bankID]]}/#{para[logonReq[:MID]]}/#{para[logonReq[:TID]]}")==false
						then "0810,1,e4:logon request TID(#{para[logonReq[:TID]]}) or MID(#{para[logonReq[:MID]]}) maybe wrong,directory(#{dlPath}) not existed,CMDEND"
					else
					"0810,6,00,#{para[logonReq[:traceNum]]},#{nowTime},#{bankRow[0]["Bank_ID"]},#{bankRow[0]["PassWord"]},#{dlPath},CMDEND"

					# insert record into tabel 'event'
					queue << "insert into event (DateTime,Success,Bank_ID,TID,MID,SN,DownLoad_Type) values('#{nowTime}',0,'#{para[logonReq[:bankID]]}','#{para[logonReq[:TID]]}','#{para[logonReq[:MID]]}','#{para[logonReq[:SN]]}','#{para[logonReq[:dlType]]}')"	
				end
            
			end
			
			begin   
            	client.puts response
			rescue Exception => e
            	logQueue << "(#{__FILE__},#{__LINE__})[error]#{ e } at response to EDC"
			end

			#logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]out:(#{response})"}
			logQueue << "(#{__FILE__},#{__LINE__})(#{client.peeraddr}) out:(#{response})"
			#logger.info("(#{__FILE__},#{__LINE__})"){"***************************"}
		rescue Exception => e
            # Displays Error Message
            #logger.error("(#{__FILE__},#{__LINE__})"){"#{ e } (#{ e.class })"}
            logQueue << "(#{__FILE__},#{__LINE__})[error]#{ e } (#{ e.class }) from (#{client.peeraddr})"
			puts "#{ e } (#{ e.class },(#{client.peeraddr}))"
        ensure
            client.close
            #puts "ensure: Closing"
			sleep (0.5)
			#logger.close
        end
	end
end

