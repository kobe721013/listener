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

#logonReq={"cmdType", "fieldCnt", "dlType", "traceNum","bankID","TID","MID","SN","CMDEND"]
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
		
		begin        
			# create logger
			
			t=Time.new
			nowTime=t.strftime("%Y%m%d")
			logFileName=nowTime+".log"
			
			logger = Logger.new(logFileName)
			logger.datetime_format=datetime_format
			
			puts "recv from: #{client.peeraddr[2]}"
            puts "hostAddr:(#{client.addr[2]})"
            #puts "client class(#{client.class})"
            #msg = client.recv(1024)
			msg=client.gets("CMDEND")#CMDEND
			
			#logger.info("(#{__FILE__},#{__LINE__})"){"---------------------------"}
			logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]in:(#{msg})"}
                        
			para = msg.split(',')
			
			if(para[0] == "0800")
			

				response = case
					when para.length != logonReq.length 
						then "0810,1,e1:logon parameter count was #{para.length},CMDEND"
					when (para[logonReq[:dlType]] != "C" and para[logonReq[:dlType]] != "A")
						then "0810,1,e2:logon [download type] was not A or C,CMDEND"
					when (bankRow=bankData.select{|row| row["Bank_ID"].to_i==para[logonReq[:bankID]].to_i}.empty?)
						then "0810,1,e3:logon request Bank ID(#{para[logonReq[:bankID]]}) was not support,CMDEND"
					
					when File.directory?("#{rootDirectory}/#{para[logonReq[:bankID]]}/#{para[logonReq[:MID]]}/#{para[logonReq[:TID]]}")==false
						then "0810,1,e4:logon request TID(#{para[logonReq[:TID]]}) or MID(#{para[logonReq[:MID]]}) maybe wrong,directory not existed,CMDEND"
					else
					"0810,6,00,#{para[logonReq[:traceNum]]},#{t.strftime("%Y%m%d%H%M%S")},#{bankRow[:Bank_ID]},#{bankRow[:PassWord]},/home/TMS/#{para[logonReq[:bankID]]}/#{para[logonReq[:MID]]}/#{para[logonReq[:TID]]}"
					queue << "insert into event (DateTime,Success,Bank_ID,TID,MID,SN,DownLoad_Type) values('#{t.strftime("%Y%m%d%H%M%S")}',0,'#{bankRow[:PassWord]}','#{para[logonReq[:TID]]}','#{para[logonReq[:MID]]}','#{para[logonReq[:SN]]}','#{para[logonReq[:dlType]]}')"	
				end
            
			end            
            client.puts response

			logger.info("(#{__FILE__},#{__LINE__})"){"[#{client.peeraddr[2]}]out:(#{response})"}
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

