require 'mharris_ext'

class Array
  def sum
    inject { |s,i| s + i }
  end
end

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
    fattr(:abilities) { [] }
    attr_accessor :name
    def apply_abilities(side)
      abilities.each { |a| a.call(side) }
    end
  end
  
  class Purchaseable < Base
    fattr(:runes) { 0 }
    fattr(:power) { 0 }
    attr_accessor :rune_cost

  end
  
  class Hero < Purchaseable
    
    class << self
      def apprentice
        new(:runes => 1, :name => "Apprentice")
      end
      def heavy_infantry
        new(:power => 2, :name => "Heavy Infantry")
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
    class << self
      def cultist
        new(:power_cost => 2, :name => "Cultist", :honor_earned => 1)
      end
    end
  end
end



class Game
  fattr(:sides) { [] }
  fattr(:center) { Center.new(:game => self) }
  fattr(:void) { Void.new }
  fattr(:honor) { 60 }
  fattr(:deck) { CenterDeck.starting }
  
end

class Side
  include FromHash
  attr_accessor :game
  fattr(:discard) { Discard.new(:side => self) }
  fattr(:deck) { PlayerDeck.starting(:side => self) }
  fattr(:hand) { Hand.new(:side => self) }
  fattr(:played) { Played.new(:side => self) }
  fattr(:constructs) { Constructs.new(:side => self) }
  fattr(:honor) { 0 }
  def draw_hand!
    5.times { draw_one! }
  end
  def draw_one!
    hand << deck.draw_one
  end
  def play(card)
    played << card
    hand.remove(card)
  end
  def purchase(card)
    discard << card
    game.center.remove(card)
    card.apply_abilities(self)
    played.pool.runes -= card.rune_cost
  end
  def defeat(monster)
    game.void << monster
    game.center.remove(monster)
    monster.apply_abilities(self)
    played.pool.power -= monster.power_cost
  end
  def end_turn!
    played.discard!
    hand.discard!
    draw_hand!
  end
  def total_cards
    [hand,played,deck,discard].map { |x| x.size }.sum
  end
end

class Pool
  fattr(:runes) { 0 }
  fattr(:power) { 0 }
end

class Cards
  include FromHash
  include Enumerable
  attr_accessor :side, :game
  fattr(:game) { side.game }
  fattr(:cards) { [] }
  def <<(c)
    cards << c
  end
  def remove(c)
    self.cards -= [c]
  end
  def each(&b)
    cards.each(&b)
  end
  def shuffle!
    self.cards = cards.sort_by { |x| rand() }
  end
  def empty?
    size == 0
  end
  def size
    cards.size
  end
  def first
    cards.first
  end
  def pop
    cards.pop
  end
  def clear!
    self.cards = []
  end
end

class Discard < Cards; end

class PlayerDeck < Cards
  def draw_one
    fill_from_discard! if empty?
    cards.pop
  end
  def fill_from_discard!
    self.cards = side.discard.cards
    side.discard.cards = []
    shuffle!
  end
  def self.starting(ops={})
    res = new(ops)
    10.times { res << Card::Hero.apprentice }
    res
  end
end

class Hand < Cards
  def play_all!
    each { |c| side.play(c) }
  end
  def discard!
    each { |c| side.discard << c }
    clear!
  end
end

class Played < Cards
  fattr(:pool) { Pool.new }
  def apply(card)
    card.apply_abilities(side)
    pool.runes += card.runes
    pool.power += card.power
  end
  def <<(card)
    super
    apply(card)
    
    if card.kind_of?(Card::Construct)
      remove(card)
      side.constructs << card
    end
  end
  def discard!
    each { |c| side.discard << c }
    clear!
    self.pool!
  end
end

class Void < Cards; end

class Center < Cards
  def fill!
    while size < 6
      self << game.deck.pop
    end
  end
  def remove(card)
    super
    fill!
  end
end

class CenterDeck < Cards
  class << self
    def starting
      res = new
      100.times { res << Card::Hero.standin }
      res
    end
  end
end

class Constructs < Cards
  def apply!
    each { |c| side.played.apply(c) }
  end
end

module Ability
  class Base
    include FromHash
  end

  class Banish < Base
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