module Parse
  class InputFile
    fattr(:raw_lines) do
      require 'csv'
      res = []
      f = File.expand_path(File.dirname(__FILE__)) + "/../input/cards_spaced.csv"
      CSV.foreach(f,:headers => true, :row_sep => "\n", :quote_char => '"') do |row|
        h = {}
        row.each do |k,v|
          #puts [k,v].inspect
          if k.present?
            k = k.downcase.strip.gsub(' ','_')
            v = v.strip if v
            v = nil if v.blank?
            h[k] = v
          end
        end
        #raise h.inspect if h['name'] == 'Flytrap Witch'
        res << h if h['name']
      end
      res
    end
    fattr(:lines) do
      raw_lines.map { |x| Line.new(:raw => x) }
    end
    fattr(:cards) do
      lines.map { |x| x.cards }.flatten
    end
  end
end