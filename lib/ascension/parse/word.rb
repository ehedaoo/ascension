module Parse
  class Word
    include FromHash
    attr_accessor :raw
    def self.parsed(ops)
      #ops[:raw] = ops[:raw].gsub("other_side-","")
      new(ops)
    end
    fattr(:main) do
      raise "trophy" if raw.to_s =~ /trophy/
      a = raw.split("-")
      #raise "bad stuff #{raw}" if a.first == 'invokable'
      a.last
    end
    fattr(:modifier) do
      a = raw.split("-")
      if a.size == 1
        nil
      elsif a.first == 'invokable'
        a.first
      else
        nil
        #raise "unknown #{a.inspect}"
      end
    end
    fattr(:word_blk) do
      Words.instance.words[main.to_s] || (raise "no block for #{raw}")
    end
    def occured?(side)
      #side = side.other_side if modifier == "other_side"
      if word_blk.arity == 1
        side.events.cond?(&word_blk)
      else
        word_blk[side,nil]
      end
    end
    def add_ability(card)
      Phrase::Base.abilities_target(card,modifier) << word_blk
    end
  end
end