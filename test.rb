

name=["kobe","Timac","s'onel"]

array=[24,1,34]
puts name.last
hash={:A=>0,:B=>1,:C=>2}


=begin
hash=[]
array.each_index{|a| 
	puts "index(#{a})"
	#t={name[a]=>array[a]}
	#puts "t:(#{t})"
	hash << {name[a]=>array[a]}
}

puts "hash:#{hash[0]["kobe"]}"
=end

x=9
s=case
	when (name[hash[:A]]!="kobe" and name[hash[:B]]!="222")
		then "not 111 and 222"
	else
		"OK"
end
puts "s(#{s})"
=begin
	response= case
		when x!=9 then "not equal 9"	
		when x>9 then ">9"
		else "<9"
	end

	puts response
=end
t=Time.new
puts "now Time (#{t.strftime("%Y%m%d%H%M%S")})"

s=case
 when File.directory?("/home/kobe/projects/") == false
	then "not exit"
else
	"exists"
end
puts s
