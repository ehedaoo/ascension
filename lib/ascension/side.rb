class Side
  include FromHash
  setup_mongo_persist :discard, :deck, :hand, :played, :constructs, :honor, :side_id, :choices, :ai, :turns, :events
  def addl_json_attributes
    %w(last_turn current_turn deck_honor)
  end
  attr_accessor :game, :ai
  fattr(:discard) { Discard.new(:side => self) }
  fattr(:deck) { PlayerDeck.starting(:side => self) }
  fattr(:hand) { Hand.new(:side => self) }
  fattr(:played) { Played.new(:side => self) }
  fattr(:constructs) { Constructs.new(:side => self) }
  fattr(:honor) { 0 }
  fattr(:side_id) { rand(100000000000000) }
  fattr(:choices) { [] }
  fattr(:ability_tracker) { AbilityTracker.new(:side => self) }

  fattr(:turns) { [] }
  def current_turn
    self.turns << Turn.new if turns.empty?
    turns.last
  end
  def last_turn
    turns.select { |x| x.played_cards.size > 0 }.last.tap { |x| return x if x }
    current_turn
  end

  def draw_hand!
    5.times { draw_one! }
  end
  def draw_one!
    hand << deck.draw_one
  end
  def check_pending_choice!
    raise PendingChoiceError.new if choices.size > 0
  end
  def play(card)
    check_pending_choice!
    played << card
    hand.remove(card)
    current_turn.played_cards << card
  end
  def acquire_free(card)
    discard << card
    game.center_wc.remove(card)
    fire_event Event::CardPurchased.new(:card => card)
    current_turn.engaged_cards << card
  end
  def purchase(card)
    acquire_free(card)
    #card.apply_abilities(self)
    #played.pool.runes -= card.rune_cost
    played.pool.deplete_runes(card)
  end
  def defeat(monster)
    defeat_free(monster)
    played.pool.power -= monster.power_cost
  end
  def defeat_free(monster)
    game.void << monster
    game.center.remove(monster) unless monster.name =~ /cultist/i && !game.center.include?(monster)
    
    fire_event Event::MonsterKilled.new(:card => monster, :center => true)
    
    played.pool.runes += monster.runes
    monster.apply_abilities(self)
    current_turn.engaged_cards << monster
  end
  def engage(card)
    check_pending_choice!
    #debugger if $mega_debugger
    if card.monster?
      defeat(card)
    else
      purchase(card)
    end
  end
  def engage_free(card)
    if card.monster?
      defeat_free(card)
    else
      acquire_free(card)
    end
  end
  def engageable_cards
    game.center_wc.engageable_cards(self) 
  end
  def end_turn!
    check_pending_choice!
    played.discard!
    hand.discard!
    constructs.apply!
    draw_hand!
    self.turns << Turn.new

    fire_event Event::EndTurn.new
    
  end
  def total_cards
    [hand,played,deck,discard].map { |x| x.size }.sum
  end
  
  fattr(:events) { Event::Events.new(:side => self) }
  def fire_event(event)
    events << event
  end
  def other_side
    res = game.sides.reject { |x| x.side_id == side_id }
    raise "bad" unless res.size == 1
    res = res.first
    #puts "in other side, this side is #{side_id} and other side is #{res.side_id}"
    res
  end
  def gain_honor(num)
    self.honor += num
    game.honor -= num if game
  end
  def to_s_status
    res = []
    res << "Center " + game.center.to_s_cards
    res << "Hand " + hand.to_s_cards if hand.size > 0
    res << "Played " + played.to_s_cards if played.size > 0
    res << "Constructs " + constructs.to_s_cards unless constructs.empty?
    res << "Pool " + played.pool.to_s
    res << "Honor #{honor} (#{game.honor})"
    res.join("\n")
  end
  def print_status!
    puts to_s_status
  end


  def self.card_place_names
    [:hand,:discard,:deck,:played,:constructs]
  end
  def card_places
    klass.card_place_names.map { |x| send(x) }
  end

  def after_mongo_load
    %w(discard deck hand played constructs).each do |m|
      send(m).side = self
    end
    choices.each do |c|
      c.side = self
    end
    ai.side = self if ai

    card_places.each do |cards|
      cards.hydrate!
      cards.each { |x| x.parent_side = self }
    end
  end

  def deck_honor
    card_places.map do |cards|
      cards.map do |card|
        card.respond_to?(:honor) ? card.honor : 0
      end
    end.flatten.map { |x| x || 0 }.sum
  end

  class << self
    def ai(ops)
      res = new(ops)
      res.ai = AI::Basic.new(:side => res)
      res
    end
  end
end