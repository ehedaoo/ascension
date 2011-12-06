module Parse
  def self.reg_word(word,&b)
    Words.instance.reg_word(word,&b)
  end
  
  class Words
    class << self
      fattr(:instance) { new }
    end
    fattr(:words) { {} }
    def reg_word(word,&b)
      words[word.to_s] = b
      words["first_#{word}"] - lambda do |event|
        b.call(event) && event.first
      end
    end
  end
  
  class Word
    include FromHash
    attr_accessor :raw, :realm, :type
    def self.parsed(ops)
      new(ops).tap { |x| x.parse! }
    end
    fattr(:without_first) do
      raw.to_s.gsub(/^first_/,"")
    end
    def first?
      raw.to_s =~ /^first_/
    end
    def parse!
      if without_first =~ /^(.+)_hero_played$/
        self.realm = $1
        self.type = "hero_played"
      else
        raise without_first
      end
    end
  end
  
  module Phrase
    def self.phrase_class(raw)
      a = raw.split(" ")
      h = {"on" => On, "if" => If}
      if a.size == 3
        h[a[1]]
      else
        Basic
      end
    end
    def self.parsed(raw)
      cls = phrase_class(raw)
      cls.new(:raw => raw)
    end
    
    class Base
      include FromHash
      attr_accessor :raw, :category
      fattr(:before_clause) { raw.split(" ").first }
      fattr(:after_clause) { raw.split(" ").last }
      fattr(:after_word) do
        Word.parsed(:raw => after_clause)
      end
      def trigger; nil; end
      def mod_card(card)
        card.triggers << trigger if trigger
      end
      
      def add_honor(side)
        side.honor += before_clause.to_i
      end
    end
    
    class On < Base
      fattr(:trigger) do
        lambda do |event, side|
          if after_word.realm.to_s == event.card.realm.to_s
            send(category, side)
          end
        end
      end
    end
    
    class If < Base
    end
  end
  
  
end

Parse.reg_word :lifebound_hero_played do |event|
  event.kind_of?(Event::HeroPlayed) && event.card.realm == :lifebound
end