def stuff
  rows = Parse::InputFile.new.raw_lines

  def size_in_csv(val)
    val = val.to_s.strip
    res = val.length
    if val =~ /,/
      puts "val #{val} #{res}"
      res += 2 
    end
    res
  end

  max_size = {}
  rows.each do |row|
    row.each do |field,val|
      new_max = [size_in_csv(val),max_size[field]||0,field.length].max
      max_size[field] = new_max
    end
  end

  CSV.open("vol/cards_spaces.csv","w") do |csv|
    csv << max_size.keys.map do |field|
      field.lpad(max_size[field]," ")
    end
    rows.each do |row|
      vals = []
      row.each do |field,val|
        val = val.to_s.strip
        val = val.lpad(max_size[field]," ") unless val =~ /,/
        vals << val
      end
      csv << vals
    end
  end
end

require 'pp'
pp Parse::InputFile.new.raw_lines.select { |x| x['name'] =~ /lidless/i }.first
pp Parse::InputFile.new.cards.first