module Parse
  class Card
    include FromHash
    def self.input_field(*args)
      attr_accessor *args
    end
    input_field :rune_cost, :honor_given, :power, :runes, :draw
    input_field :banish_center, :banish_hand_discard
    input_field :special_abilities, :realm, :name, :honor, :power_cost
    input_field :discard_from_hand, :banish_hand, :runes_for_honor
    fattr(:card_class) do
      ::Card::Hero
    end
    def make_parsed_phrase_obj(raw, cat)
      return nil unless raw
      #return nil if raw =~ /foreach/
      Phrase.parsed(raw).tap { |x| x.category = cat }
    end

    # Raw Cell is the text from the csv file for this column
    # 
    # method_name_or_ability_class is one of two things:
    # 1. the symbol for the method to call for this column
    # 2. The Class that represents this ability
    def mod_for_phrases(raw_cell, method_name_or_ability_class, card_to_setup)
      return unless raw_cell
      #puts [raw,cat,card_class,name].inspect
      raw_cell.split(/[,;]/).each do |raw_cell_part|
        p = make_parsed_phrase_obj(raw_cell_part,method_name_or_ability_class)
        p.mod_card(card_to_setup) if p
      end
    end
    fattr(:card) do
      res = card_class.new(:name => name, :realm => realm, :honor => honor.to_i)

      #raise "witch #{inspect}" if name == 'Flytrap Witch'

      #raise "#{name} #{honor_given}" if honor_given.to_i > 0

      mod_for_phrases(runes, :runes, res)
      mod_for_phrases(honor_given,:add_honor,res)
      mod_for_phrases(power, :add_power, res)
      mod_for_phrases(draw, :draw_cards, res)
      
      mod_for_phrases(banish_hand, Ability::BanishHand, res)
      mod_for_phrases(banish_center, Ability::BanishCenter, res)
      mod_for_phrases(banish_hand_discard, Ability::BanishHandDiscard, res)
      mod_for_phrases(discard_from_hand, Ability::DiscardFromHand, res)
      mod_for_phrases(runes_for_honor, Ability::RunesForHonor, res)
      
      if special_abilities
        word = Word.parsed(:raw => special_abilities)
        #res.abilities << word.word_blk
        word.add_ability(res)
      end
      
      res.power_cost = power_cost.to_i if res.monster?
      res.rune_cost = rune_cost.to_i unless res.monster?
      
      res
    end
  end
end