module Parse
  module Phrase
    class Basic < Base
      class << self
        def basic_mod_card_proc
          lambda do |card,phrase|
            if phrase.category == :runes
              card.runes += phrase.before_clause.to_i if phrase.before_clause.to_i > 0
            elsif phrase.category == :power || phrase.category == :add_power
              card.power += phrase.before_clause.to_i
            elsif phrase.category == :add_honor
              #raise "in honor part"
              card.honor_earned = phrase.before_clause.to_i
            elsif phrase.category == :draw_cards
              phrase.abilities_target(card) << lambda do |side|
                if phrase.modifier == 'other_side'
                  phrase.draw_cards(side.other_side)
                else
                  phrase.draw_cards(side)
                end
              end
            elsif phrase.category.kind_of?(Class)
              phrase.abilities_target(card) << phrase.category.new(:optional => phrase.optional, :parent_card => card)
            else
              raise "unknown category #{phrase.category}"
            end
          end
        end
      end
      def mod_card(card)
        if modifier == 'trophy'
          trophy_card = ::Card::Hero.new
          card.trophy = trophy_card
          self.class.basic_mod_card_proc[trophy_card,self]
        else
          self.class.basic_mod_card_proc[card,self]
        end
      end
      def modifier
        super
      end
    end 
  end
end