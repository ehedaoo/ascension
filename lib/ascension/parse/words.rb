module Parse
  class Words
    class << self
      fattr(:instance) { new }
    end
    fattr(:words) { {} }
    fattr(:abilities) { {} }
    def reg_word(word,ability=nil,&b)
      b ||= ability
      words[word.to_s] = b
      words["first_#{word}"] = lambda do |event|
        b.call(event) && event.first
      end
      words["first_other_#{word}"] = lambda do |event,card|
        b.call(event) && event.first(:excluding => card)
      end
    end
    def reg_ability(word,ability)
      abilities[word.to_s] = ability
    end
  end
end