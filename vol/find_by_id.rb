class File
  def self.pp(file,obj)
    require 'pp'

    File.open(file,"w") do |f|
      PP.pp(obj,f)
    end
  end
end

puts Game.collection.count
puts 'end'

#Game.reset!

g = Game.collection.find_one_object
File.pp "vol/dmp.json",g.as_json
File.create "vol/dmp2.json",g.to_mongo_hash.inspect

c = Card::Monster.cultist
puts c.to_mongo_hash
puts c.as_json