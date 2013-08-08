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

	rs=con.query("Select * from event")
	n_rows=rs.num_rows
	puts "table event, total rows (#{n_rows})"

=begin
    n_rows.times do
        res=rs.fetch_row.join("\s")
		puts "res.class:(#{res.class}), fetch_row.class:(#{rs.fetch_row.class})"
		p res
		#puts rs.fetch_row.join("\s")
    end
=end
	rs.each_hash do |row|
		puts "id:#{row['ID']}"

	end


rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end
