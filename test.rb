
t=Time.new
nowTime=t.strftime("%Y%m%d")

file=nowTime+".log"

detailTime=t.strftime("%Y/%m/%d-%H:%M:%S")

puts "file:#{file}, nowTime:#{nowTime}, detailTime:#{detailTime}"
