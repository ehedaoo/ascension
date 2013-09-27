file = "lib/ascension/input/cards_spaced.csv"
require 'csv'

did_headers = false
CSV.open("vol/cards_trim.csv", "w") do |output|
  CSV.foreach(file, :headers => true) do |source_row|
    vals = {}
    source_row.each { |k,v| vals[k.strip] = v.strip }
    if !did_headers
      output << vals.keys
      did_headers = true
    end
    output << vals.values
  end
end
