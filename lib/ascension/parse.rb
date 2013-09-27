%w(parse card input_file line phrase word words setup).each do |f|
  load File.dirname(__FILE__) + "/parse/#{f}.rb"
end