

def save_image(name)
  require 'google-search'
  url = Google::Search::Image.new(:query => "Ascension #{name}").first.uri
  File.append "vol/images.csv","\"#{name}\",\"#{url}\"\n"
end

def save_images
  load "lib/ascension.rb"
  Parse.cards.map { |x| x.name }.uniq.each do |name|
    save_image(name)
  end
end

class ImageMap
  fattr(:map) do
    require 'csv'
    res = {}
    f = File.expand_path(File.dirname(__FILE__)) + "/images.csv"
    CSV.foreach(f, :headers => true) do |row|
      res[row['name']] = row['url'].to_s if row['url'].to_s =~ /\.(png|jpg)/
    end
    res
  end

  def get(name)
    map[name]
  end

  def cards_without_image
    Parse.cards.map { |x| x.name }.uniq.reject { |x| map[x] }
  end

  class << self
    fattr(:instance) { new }
    def method_missing(sym,*args,&b)
      instance.send(sym,*args,&b)
    end
  end
end