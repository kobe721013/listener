require 'mysql'

begin
    con = Mysql.new 'localhost', 'root', '123456', 'Listen'
    puts con.get_server_info
    rs = con.query 'SELECT VERSION()'
    puts rs.fetch_row    
    puts "con.class:(#{con.class}), rs.calss:#{rs.class}"

	con.list_dbs.each do |db|
        puts db
    end

	rs=con.query("Select * from bank")
	n_rows=rs.num_rows
	puts "bank event, total rows (#{n_rows})"

=begin
    n_rows.times do
        res=rs.fetch_row.join("\s")
		puts "res.class:(#{res.class}), fetch_row.class:(#{rs.fetch_row.class})"
		p res
		#puts rs.fetch_row.join("\s")
    end
=end
	array=[]
	rs.each_hash do |row|
		#puts "bank id:#{row['Bank_ID']}"
		array << row
	end
	puts "array:#{array}"
	

	puts "#{(tmp=array.select{|row| row["Bank_ID"].to_i=="0999".to_i}).empty?}, tmp(#{tmp})"
	
	result=array.select{|row| row["Bank_ID"].to_i=="0999".to_i}
	puts "result.class#{result.class}"
	response = case
		when(result.empty?)
			puts "null"
		else
			puts "#{result[0]["PassWord"]}111"
	end
	#puts "#{array.select{|row| row["Bank_ID"].to_i=="0999".to_i}}"




rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end
