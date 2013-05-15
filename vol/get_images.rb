load "lib/ascension.rb"

class Array
  def uniq_by
    res = {}
    each { |x| res[yield(x)] = x }
    res.values
  end
end

ImageMap.instance!

rows = Parse.cards.uniq_by { |x| x.name }.map do |card|
  "<tr><td>#{card.name}</td><td><img src='#{card.image_url}' height=225px width=162px></td></tr>"
end.join("\n")
str = "<table>#{rows}</table>"
File.create "vol/images.html",str
