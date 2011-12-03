require 'mharris_ext'
require 'rchoice'

class Array
  def sum
    inject { |s,i| s + i }
  end
end

class Object
  def klass
    self.class
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

%w(card cards ability).each do |f|
  require File.dirname(__FILE__) + "/ascension/#{f}"
end