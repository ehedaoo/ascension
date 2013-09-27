str = <<EOF
Card
  Ability
    CardChoice
      RChoice
EOF

module Ability
  class ChoiceInstance
    include FromHash
    attr_accessor :choice, :side

    setup_mongo_persist :choice, :choice_id, :config_params
    def addl_json_attributes
      %w(choosable_cards name optional)
    end
    def name
      choice.class.to_s
    end
    fattr(:optional) do
      choice.optional
    end

    fattr(:choice_id) { rand(100000000000000) }
    fattr(:config_params) do
      choice.config_params
    end

    fattr(:choosable_cards) do
      res = choice.choosable_cards(side)
      res = res.cards if res && res.respond_to?(:cards)
      res
    end
    def needs_decision?
      #return false unless choice.respond_to?(:choosable_cards)# && choosable_cards.size > 0
      #return false unless choosable_cards
      choice.respond_to?("needs_choice?") && choice.needs_choice?
    end
    def save!
      if needs_decision?
        if choice.kind_of?(Ability::KeepOneConstruct)
          #puts "this side is #{side.side_id} other is #{side.other_side.side_id}"
        end
        side.choices << self
      else
        #raise choice.inspect
        choice.call(side)
      end
    end

    def execute!(chosen_card)
      if chosen_card
        choice.action(chosen_card,side)
      elsif choice.optional
        # do nothing  
      elsif choosable_cards.empty?
        #do nothing
      else
        raise "#{name} has to make a choice. options: " + choosable_cards.map { |x| x.name }.inspect
      end
      delete!
    end

    def delete!
      old = side.choices.size
      side.choices -= [self]
      raise "Bad sizes" unless old-1 == side.choices.size
    end
  end


  class Base
    def side_for_card_choice(side)
      side
    end
    fattr(:optional) { false }
    include FromHash
    attr_accessor :parent_card
    setup_mongo_persist :parent_card, :optional
    def call_until_nil(side)
      loop do
        choice = call(side)
        yield if block_given?
        return unless choice.choice.chosen_option && choosable_cards(side).size > 0
      end
    end
    def choice_instance(side)
      ChoiceInstance.new(:choice => self, :side => side_for_card_choice(side))
    end
  end
  
  class BaseChoice < Base
    fattr(:config_params) { {} }
    def side_for_card_choice(side)
      side
    end
    def card_choice(side)
      CardChoice.new(:ability => self, :side => side_for_card_choice(side))
    end
    def call(side)
      card_choice(side).tap { |x| x.run! }
    end
    def needs_choice?
      true
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
      res = RChoice::Choice.new(:optional => ability.optional, :name => ability.klass.to_s, :parent_obj => self)
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
  end
  
  class BanishCenter < Banish
    def action(card,side)
      side.game.center.banish(card)
    end
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

  class BanishHand < Banish
    def action(card,side)
      side.hand.banish(card)
    end
    def choosable_cards(side)
      side.hand.cards
    end
  end

  class DiscardFromHand < BaseChoice
    def action(card,side)
      side.hand.discard(card)
    end
    def choosable_cards(side)
      side.hand.cards
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
      side.acquire_free(card)
    end
  end

  class AcquireCenter < BaseChoice
    #attr_accessor :max_rune_cost
    def choosable_cards(side)
      #side.game.center_wc.select { |x| x.hero? }.each { |x| puts [x.name,x.rune_cost].inspect }
      side.game.center.cards
    end
    def action(card,side)
      side.engage_free(card)
    end
  end

  class AcquireConstruct < BaseChoice
    #attr_accessor :max_rune_cost
    def choosable_cards(side)
      #side.game.center_wc.select { |x| x.hero? }.each { |x| puts [x.name,x.rune_cost].inspect }
      side.game.center.cards.select { |x| x.kind_of?(Card::Construct) }
    end
    def action(card,side)
      side.engage_free(card)
    end
  end
  
  class CopyHero < BaseChoice
    def choosable_cards(side)
      res = side.played.select { |x| x }
      #raise res.inspect
    end
    def action(card,side)
      side.played.apply(card)
    end
  end

  class OtherSideChoice < BaseChoice
    def side_for_card_choice(side)
      side.other_side
    end
  end
  
  class DiscardConstruct < OtherSideChoice
    def choosable_cards(side)
      side.constructs
    end
    def action(card,side)
      side.constructs.discard(card)
    end
  end
  
  class KeepOneConstruct < OtherSideChoice
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
    def choosable_cards(side)
      side.other_side.hand
    end
    def action(card,side)
      side.other_side.hand.remove(card)
      side.hand << card
    end
  end

  class RunesForHonor < BaseChoice
    def needs_choice?
      false
    end
    def invokable?(side)
      side.played.pool.runes >= 4
    end
    def call(side)
      side.played.pool.deplete_runes Card::Hero.new(:rune_cost => 4)
      side.gain_honor 3
    end
  end

  class ReturnMechanaConstructToHand < BaseChoice
    def choosable_cards(side)
      side.constructs.select { |x| x.mechana? && x.name != 'Dream Machine' }
    end
    def action(card,side)
      side.constructs.remove(card)
      card.invoked_ability = false
      card.triggers.each do |t|
        t.reset! if t.respond_to?("reset!")
      end
      side.hand << card
    end
    def invokable?(side)
      side.constructs.select { |x| x.mechana? }.size > 1
    end
  end

  class GuessTopCardFor3 < BaseChoice
    def choosable_cards(side)
      side.card_places.map { |x| x.select { |x| x } }.flatten.uniq_by { |x| x.name }
    end
    def action(card,side)
      if side.deck.last.name == card.name
        side.gain_honor 3
      end
      side.draw_one!
    end
  end

  class ChooseAbility < BaseChoice
    def needs_choice?
      true
    end
    fattr(:ability_choices) { [] }
    def choosable_cards(side)
      ability_choices
    end
    def action(ability,side)
      #ability.call(side)
      if ability.respond_to?(:choice_instance)
        ability.choice_instance(side).save!
        raise "bad size #{side.choices.size}" unless side.choices.size == 2
      else
        ability.call(side)
      end
    end
  end

  class UpgradeHeroInHand < BaseChoice
    def choosable_cards(side)
      side.hand.select { |x| x }
    end
    def action(card,side)
      side.hand.banish(card)
      #side.hand << Card::Hero.mystic
      side.apply_ability PickCenterHeroForHand.new(max_honor: (card.honor||0) + 2)
    end
  end

  class PickCenterHeroForHand < BaseChoice
    def max_honor=(h)
      self.config_params[:max_honor] = h
    end
    def max_honor
      config_params[:max_honor]
    end
    def choosable_cards(side)
      side.game.center_wc.select { |x| x.hero? && x.honor <= max_honor }
    end
    def action(card,side)
      side.game.center.remove(card) unless card.basic_card?
      side.hand << card
    end
  end
end