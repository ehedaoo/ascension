module Ability
  class Base
    fattr(:optional) { false }
    include FromHash
    def call_until_nil(side)
      loop do
        choice = call(side)
        yield if block_given?
        return unless choice.choice.chosen_option && choosable_cards(side).size > 0
      end
    end
  end
  
  class BaseChoice < Base
    def call(side)
      CardChoice.new(:ability => self, :side => side).tap { |x| x.run! }
    end
  end
  
  class CardChoice
    include FromHash
    attr_accessor :ability, :side
    fattr(:choosable_cards) do
      ability.choosable_cards(side)
    end
    class << self
      fattr(:chooser) {}
    end
    fattr(:choice) do
      res = Choice::Choice.new(:optional => ability.optional, :name => ability.klass.to_s)
      choosable_cards.each do |card|
        res.add_option card
      end
      res.action_blk = lambda { |card| ability.action(card,side) }
      res.chooser = klass.chooser
      res
    end
    def run!
      choice.execute!
    end
  end

  class Banish < BaseChoice
    def action(card,side)
      side.game.center.banish(card)
    end
  end
  
  class BanishCenter < Banish
    def choosable_cards(side)
      side.game.center
    end
  end
  
  class BanishHandDiscard < Banish
    def action(card,side)
      if side.hand.include?(card)
        side.hand.banish(card)
      else
        side.discard.banish(card)
      end
    end
    def choosable_cards(side)
      side.hand.cards + side.discard.cards
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
  
  class DoCenterAction < BaseChoice
    def optional; true; end
    def choosable_cards(side)
      side.game.center_wc.select { |x| can?(x,side) }
    end
    def can?(card,side)
      if card.monster?
        raise card.name unless card.power_cost
        side.played.pool.power >= card.power_cost
      else
        side.played.pool.can_purchase?(card)
      end
    end
    def action(card,side)
      if card.monster?
        side.defeat(card)
      else
        side.purchase(card)
      end
    end
  end
  
  class KillMonster < BaseChoice
    attr_accessor :max_power
    def choosable_cards(side)
      side.game.center_wc.select { |x| x.monster? && x.power_cost <= (max_power||99) }
    end
    def action(card,side)
      side.defeat(card)
    end
  end
  
  class AcquireHero < BaseChoice
    attr_accessor :max_rune_cost
    def choosable_cards(side)
      #side.game.center_wc.select { |x| x.hero? }.each { |x| puts [x.name,x.rune_cost].inspect }
      side.game.center_wc.select { |x| x.hero? && x.rune_cost <= (max_rune_cost||99) }
    end
    def action(card,side)
      side.purchase(card)
    end
  end
  
  class CopyHero < BaseChoice
    def choosable_cards(side)
      side.played
    end
    def action(card,side)
      side.played.apply(card)
    end
  end
  
  class DiscardConstruct < BaseChoice
    def call(side)
      CardChoice.new(:ability => self, :side => side.other_side).tap { |x| x.run! }
    end
    def choosable_cards(side)
      side.constructs
    end
    def action(card,side)
      side.constructs.discard(card)
    end
  end
  
  class KeepOneConstruct < BaseChoice
    def call(side)
      CardChoice.new(:ability => self, :side => side.other_side).tap { |x| x.run! }
    end
    def choosable_cards(side)
      side.constructs
    end
    def action(card,side)
      other = side.constructs.reject { |x| x == card }
      other.each do |o|
        side.constructs.discard(o)
      end
    end
  end
  
  class TakeOpponentsCard < BaseChoice
    def call(side)
      CardChoice.new(:ability => self, :side => side).tap { |x| x.run! }
    end
    def choosable_cards(side)
      side.other_side.hand
    end
    def action(card,side)
      side.other_side.hand.remove(card)
      side.hand << card
    end
  end
end