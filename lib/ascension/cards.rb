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
  def include?(c)
    cards.include?(c)
  end
  def banish(card)
    remove(card)
    game.void << card
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
    
    side.fire_event(Event::CardPlayed.new(:card => card))
    
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
  def banish(card)
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