module Card
  module HonorEarned
    attr_accessor :honor_earned
    def honor_earned=(h)
      @honor_earned = h
      self.abilities << Ability::EarnHonor.new(:honor => h)
    end
  end
  
  class Base
    include FromHash
    include HonorEarned
    attr_accessor :realm
    
    # abilities are things that happen when a card is put into play or defeated
    # abilities can be conditional on whether other things have already happened
    fattr(:abilities) { [] }
    
    # triggers are things than happen when external events occur.  
    fattr(:triggers) { [] }
    
    attr_accessor :name
    def apply_abilities(side)
      abilities.each { |a| a.call(side) }
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
  end
  
  class Purchaseable < Base
    fattr(:runes) { 0 }
    fattr(:power) { 0 }
    attr_accessor :rune_cost
    def mechana?
      realm == :mechana
    end
  end
  
  class Hero < Purchaseable
    class << self
      def apprentice
        new(:runes => 1, :name => "Apprentice")
      end
      def mystic
        new(:runes => 2, :name => 'Mystic', :rune_cost => 3)
      end
      def militia
        new(:power => 1, :name => 'Militia')
      end
      def heavy_infantry
        new(:power => 2, :name => "Heavy Infantry", :rune_cost => 2)
      end
      def standin
        new(:rune_cost => 2, :name => "Standin")
      end
      def arha
        new(:rune_cost => 1, :name => "Arha Initiate").tap do |h|
          h.abilities << Ability::Draw.new
        end
      end
    end
  end
  
  class Construct < Purchaseable
    class << self
      def shadow_star
        new(:power => 1)
      end
    end
  end

  class Monster < Base
    attr_accessor :power_cost
    fattr(:runes) { 0 }
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