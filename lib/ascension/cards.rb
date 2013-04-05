class Cards
  include FromHash
  include Enumerable
  setup_mongo_persist :cards
  attr_accessor :side, :game
  fattr(:game) { side.game }
  fattr(:cards) { [] }
  def <<(c)
    cards << c
  end
  def remove(c)
    raise "#{c} not here" unless cards.include?(c)
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
  def index(obj)
    cards.index(obj)
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
  def []=(i,card)
    cards[i] = card
  end
  def [](i)
    cards[i]
  end
  def to_s_cards
    map { |x| x.name }.join(" | ")
  end
  def get_one(name)
    res = find { |x| x.name == name }
    raise "couldn't find #{name}" unless res
    self.cards -= [res]
    res
  end
  def hydrate!
    self.cards = map { |x| x.hydrated }
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
    8.times { res << Card::Hero.apprentice }
    2.times { res << Card::Hero.militia }
    res.shuffle!
    res
  end
end

class Hand < Cards
  def play_all!
    while size > 0
      side.play(first)
    end
  end
  def discard!
    each { |c| side.discard << c }
    clear!
  end
end

class Played < Cards
  setup_mongo_persist :cards, :pool
  fattr(:pool) { Pool.new }
  def apply(card)
    pool.runes += card.runes
    pool.power += card.power
    card.apply_abilities(side)
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

module Selectable
  def engageable_cards(side)
    select { |x| can?(x,side) }
  end
  def can?(card,side)
    if card.monster?
      raise card.name unless card.power_cost
      side.played.pool.power >= card.power_cost
    else
      side.played.pool.can_purchase?(card)
    end
  end
end

class Center < Cards
  def fill!
    (0...size).each do |i|
      if self[i].name == 'Dummy'
        self[i] = game.deck.pop
      end
    end

    while size < 6
      self << game.deck.pop
    end
  end
  def remove(c)
    raise "#{c} not here" unless include?(c)
    i = index(c)
    self[i] = Card.dummy
    fill!
  end
  def banish(card)
    super
    fill!
  end
end

class CenterWithConstants < Cards
  attr_accessor :game
  include FromHash
  include Selectable
  fattr(:constant_cards) do
    [Card::Hero.mystic,Card::Hero.heavy_infantry,Card::Monster.cultist]
  end
  def cards
    game.center.cards + constant_cards
  end
  def size
    cards.size
  end
  def remove(card)
    return nil if constant_cards.map { |x| x.name }.include?(card.name)
    game.center.remove(card)
  end
  def method_missing(sym,*args,&b)
    game.center.send(sym,*args,&b)
  end
end

class CenterDeck < Cards
  class << self
    def starting
      res = new
      Parse::InputFile.new.cards.each { |c| res << c }
      res.shuffle!
      res
    end
  end
end

class Constructs < Cards
  def apply!
    each { |c| side.played.apply(c) }
  end
  def discard(card)
    remove(card)
    side.discard << card
  end
end