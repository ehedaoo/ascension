lines = `ps -ax`.split("\n").map { |x| x.strip }
words = %w(guard middleman ruby foreman spec ascension)

lines = lines.select do |line|
  words.any? do |word|
    line =~ /#{word}/
  end
end

lines.each { |x| puts x }

lines.each do |line|
  pid = line.split(" ").first
  #{}`kill #{pid}` unless pid.to_i == Process.pid
end