class BadCardEquals < RuntimeError
end

module Card
  module HonorEarned
    attr_accessor :honor_earned
    def honor_earned=(h)
      @honor_earned = h
      self.abilities << Ability::EarnHonor.new(:honor => h)
    end
  end

  class << self
    def dummy
      Base.new(:name => "Dummy")
    end

    def all_cards_hash
      fields = %w(name realm honor image_url runes power rune_cost power_cost trophy)
      constants = [Card::Hero.mystic,Card::Hero.heavy_infantry,Card::Monster.cultist,Card::Hero.militia,Card::Hero.apprentice]
      cards = Parse.cards + constants
      all = cards.uniq_by { |x| x.name }.map do |card|
        fields.inject({}) do |h,f|
          card.respond_to?(f) ? h.merge(f => card.send(f)) : h
        end
      end
      all
    end
    def card_places
      {:game => Game.local_card_place_names, :side => Side.card_place_names}
    end
    def initial_card_info
      {:cards => all_cards_hash, :places => card_places}.to_json
    end
    def basic_card_names
      ["Heavy Infantry","Mystic","Cultist","Apprentice","Militia","Standin"]
    end
    def basic?(card)
      basic_card_names.include?(card)
    end
  end

  class Base
    include FromHash
    include HonorEarned

    setup_mongo_persist :realm, :name, :card_id, :honor
    attr_accessor :parent_side, :honor

    def addl_json_attributes
      []
    end
    def restricted_json_attributes
      %w(realm honor)
    end
    def image_url
      (ImageMap.get(name) || "none").to_s
    end



    attr_accessor :realm
    
    # abilities are things that happen when a card is put into play or defeated
    # abilities can be conditional on whether other things have already happened
    fattr(:abilities) { [] }
    
    # triggers are things than happen when external events occur.  
    fattr(:triggers) { [] }

    

    fattr(:card_id) { rand(10000000000000) }
    
    attr_accessor :name
    def apply_abilities(side)
      abilities = self.abilities
      abilities = abilities.reverse if name == 'Temple Librarian'

      abilities.each do |a|
        side.apply_ability(a)
      end
    end
    def apply_triggers(event, side)
      triggers.each { |a| a.call(event, side) }
    end
    
    
    def monster?; kind_of?(Monster); end
    def hero?; kind_of?(Hero); end
    def construct?; kind_of?(Construct); end
    
    def to_s
      name
    end

    def basic_card?
      Card.basic_card_names.include?(name)
    end

    def hydrated
      return self if basic_card?
      parsed = Parse.get(name).clone

      %w(abilities triggers invokable_abilities trophy).each do |m|
        self.send("#{m}=",parsed.send(m)) if parsed.respond_to?(m)
      end
      #res.card_id = card_id
      #res
      self
    end

    def clone
      res = super
      res.card_id!
      res.abilities = res.abilities.map { |x| x.clone }
      res.triggers = res.triggers.map { |x| x.clone }
      res
    end

    

    def ==(c)
      raise BadCardEquals,"in ==, other card is nil, this card is #{inspect}" unless c
      card_id == c.card_id
    end
    def eql?(c)
      card_id == c.card_id
    end
    def equal?(c)
      card_id == c.card_id
    end
    def ===(c)
      card_id == c.card_id
    end
    def <=>(c)
      card_id <=> c.card_id
    end

    def handle_event(event,side)
      if triggers.any? { |t| t.respond_to?(:unite) && t.unite }
        #puts "got unite trigger"
      end

      triggers.each do |trigger|
        if event.respond_to?(:card) && event.card.card_id == card_id
          #raise 'same card'
          # do nothing
        else
          trigger.call(event,side)
        end
      end
    end

    fattr(:fate_abilities) { [] }


  end
  
  class Purchaseable < Base
    setup_mongo_persist :realm, :name, :runes, :power, :rune_cost, :card_id, :honor
    def restricted_json_attributes
      %w(realm honor runes power rune_cost)
    end


    fattr(:runes) { 0 }
    fattr(:power) { 0 }
    attr_accessor :rune_cost
    def mechana?
      realm == :mechana
    end
    def engage_cost
      rune_cost
    end
  end
  
  class Hero < Purchaseable
    class << self
      def apprentice
        new(:runes => 1, :name => "Apprentice")
      end
      def mystic
        new(:runes => 2, :name => 'Mystic', :rune_cost => 3, :honor => 1)
      end
      def militia
        new(:power => 1, :name => 'Militia')
      end
      def heavy_infantry
        new(:power => 2, :name => "Heavy Infantry", :rune_cost => 2, :honor => 1)
      end
      def standin
        new(:rune_cost => 2, :name => "Standin")
      end
      def arha
        new(:rune_cost => 1, :name => "Arha Initiate", :honor => 1).tap do |h|
          h.abilities << Ability::Draw.new
        end
      end
      def get_basic(card)
        card = card.downcase.gsub(" ","_")
        send(card)
      end
    end
  end
  
  class Construct < Purchaseable
    setup_mongo_persist :realm, :name, :runes, :power, :rune_cost, :card_id, :invoked_ability, :honor
    def restricted_json_attributes
      %w(realm honor runes power rune_cost)
    end
    class << self
      def shadow_star
        new(:power => 1)
      end
    end

    fattr(:invokable_abilities) { [] }
    fattr(:invoked_ability) { false }

    def has_invokable_ability
      invokable_abilities.any? { |a| !a.respond_to?("invokable?") || (parent_side && a.invokable?(parent_side)) } && !invoked_ability
    end
    def addl_json_attributes
      ["has_invokable_ability"]
    end

    def handle_event(event,side)
      apply_triggers(event,side)
      if event.key == [:end_turn]
        self.invoked_ability = false
      end
    end

    def invoked_ability=(val)
      str = "Setting invoked_ability to #{val} on #{card_id}"
      Debug.log str

      @invoked_ability = val
    end

    def save_choice_instance?(ability)
      return false unless ability.respond_to?(:choice_instance)
      return ability.needs_choice? if ability.respond_to?("needs_choice?")
      false
    end

    def invoke_abilities(side)
      invokable_abilities.each do |ability|
        if !save_choice_instance?(ability)
          ability.call(side)
        else
          ability.choice_instance(side).save!
        end
      end
      self.invoked_ability = true
    end

    def hydrated
      #puts "hydrating construct"
      res = super
      res.invoked_ability = invoked_ability
      res
    end
  end

  class Monster < Base
    attr_accessor :power_cost, :trophy
    setup_mongo_persist :realm, :name, :power_cost, :card_id
    def restricted_json_attributes
      %w(realm power_cost)
    end
    fattr(:runes) { 0 }
    def engage_cost
      power_cost
    end
    class << self
      def cultist
        new(:power_cost => 2, :name => "Cultist", :honor_earned => 1)
      end
      def cultist_standin
        new(:power_cost => 2, :name => "Cultist Standin", :honor_earned => 1)
      end
      def cultist_standin2
        new(:power_cost => 2, :name => "Cultist Standin2", :honor_earned => 1)
      end
    end
  end
end