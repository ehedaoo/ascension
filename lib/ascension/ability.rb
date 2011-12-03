module Ability
  class Base
    fattr(:optional) { false }
    include FromHash
  end
  
  class BanishChoice
    include FromHash
    attr_accessor :banish, :side
    fattr(:banishable_cards) do
      banish.banishable_cards(side)
    end
    def self.chooser; end
    fattr(:choice) do
      res = Choice::Choice.new(:optional => banish.optional)
      banishable_cards.each do |card|
        res.add_option card
      end
      res.action_blk = lambda { |card| banishable_cards.banish(card) }
      res.chooser = klass.chooser
      res
    end
    def run!
      choice.execute!
    end
  end

  class Banish < Base
    def call(side)
      BanishChoice.new(:banish => self, :side => side).run!
    end
  end
  
  class BanishCenter < Banish
    def banishable_cards(side)
      side.game.center
    end
  end
  
  class EarnHonor < Base
    attr_accessor :honor
    def call(side)
      side.game.honor -= honor
      side.honor += honor
    end
  end
  
  class Draw < Base
    def call(side)
      side.draw_one!
    end
  end
end