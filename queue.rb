require 'thread'

queue = Queue.new

producer = Thread.new{
  puts "producer new"
  5.times do |i|
    sleep rand(i) # simulate expense
    queue << i
    puts "#{i} produced, producer(#{producer})"
  end
}

puts "producer finish~~~"

consumer = Thread.new do
  puts "consumer new"
  5.times do |i|
    value = queue.pop
    sleep rand(i/2) # simulate expense
    puts "consumed #{value}, thread(#{consumer})"
  end
end

puts "consumer finish~~~ join go"

producer.join
#consumer.join
