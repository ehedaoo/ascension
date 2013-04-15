require 'mharris_ext'
require 'rchoice'
require 'mongo_persist'

def playing_on_command_line?
  $playing_on_command_line = true if $playing_on_command_line.nil?
  $playing_on_command_line
end

%w(to_json).each do |f|
  load File.dirname(__FILE__) + "/ascension/#{f}.rb"
end

def db
  Mongo::Connection.new.db('ascension')
end

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

class Events
  def fire(event)
    
  end
end

class Debug
  class << self
    def log(*args)
      #puts args.join(",")
      File.append "debug.log","#{args.first}\n"
    end
    def clear!
      File.create("debug.log","Starting Log at #{Time.now}\n")
    end
  end
end

module HandleChoices
  def handle_choices!
    sides.each do |side|
      side.choices.each do |choice|
        if side.ai
          side.ai.handle_choice(choice) 
        else
          return false
        end
      end
    end
    true
  end
end

class Game
  include HandleChoices
  setup_mongo_persist :sides, :center, :void, :honor, :deck, :turn_manager
  def addl_json_attributes
    %w(mongo_id engageable_cards constant_cards current_side_index last_update_dt)
  end

  fattr(:sides) { [] }
  fattr(:center) { Center.new(:game => self) }
  fattr(:void) { Void.new }
  fattr(:honor) { 60 }
  fattr(:deck) { CenterDeck.starting }
  fattr(:center_wc) { CenterWithConstants.new(:game => self) }
  fattr(:turn_manager) { TurnManager.new(:game => self) }

  def engageable_cards
    turn_manager.current_side.engageable_cards
  end
  def constant_cards
    center_wc.constant_cards
  end
  def current_side_index
    turn_manager.current_side_index
  end
  def last_update_dt
    Time.now
  end

  def local_card_places
    [deck,center,void]
  end
  def card_places
    res = local_card_places + sides.map { |x| x.card_places }
    res.flatten
  end

  def after_mongo_load
    center.game = self
    turn_manager.game = self

    sides.each do |s|
      s.game = self
      s.after_mongo_load
    end

    local_card_places.each do |cards|
      cards.hydrate!
    end
  end

  def find_card(card_id)
    raise "blank card id" if card_id.blank?
    card_places.each do |cards|
      res = cards.find { |x| x.card_id.to_s == card_id.to_s }
      return res if res
    end
    raise "no card #{card_id}"
  end

  class << self
    def reset!
      Game.collection.remove
      game = Game.new
      side = Side.new(:game => game)
      game.sides << side
      game.sides << Side.ai(:game => game)

      game.deck = CenterDeck.starting
      #game.deck << Parse.get("Mephit")
      game.center.fill!
      #side.deck << game.deck.get_one('Temple Librarian')
      #side.deck[-1] = Card::Hero.arha

      #side.deck << Parse.get("Temple Librarian")

      #side.deck << Parse.get("Shade ot Black Watch")
      #side.deck << Parse.get("Seer of the Forked Path")
      #side.deck << Parse.get("Demon Slayer")
      game.sides.each do |s|
        s.draw_hand!
      end
      #side.hand << game.deck.get_one('Void Thirster')
      #side.deck << game.deck.get_one('Void Initiate')

      game.mongo.save!
      game
    end
  end
end

class Turn
  include FromHash
  fattr(:engaged_cards) { [] }
  fattr(:played_cards) { [] }
  setup_mongo_persist :engaged_cards, :played_cards
end

class Side
  include FromHash
  setup_mongo_persist :discard, :deck, :hand, :played, :constructs, :honor, :side_id, :choices, :ai, :turns
  def addl_json_attributes
    %w(last_turn current_turn)
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
  def play(card)
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


  def card_places
    [hand,discard,deck,played,constructs]
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

  class << self
    def ai(ops)
      res = new(ops)
      res.ai = AI::Basic.new(:side => res)
      res
    end
  end
end

%w(card cards ability pool events parse turn_manager setup_rchoice).each do |f|
  load File.dirname(__FILE__) + "/ascension/#{f}.rb"
end

%w(basic).each do |f|
  load File.dirname(__FILE__) + "/ascension/ai/#{f}.rb"
end