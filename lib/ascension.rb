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

class Game
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

  def card_places
    places = [deck,center,void]
    sides.each do |side|
      places += [side.hand,side.discard,side.deck,side.played]
    end
    places
  end

  def after_mongo_load
    center.game = self
    turn_manager.game = self

    sides.each do |s|
      s.game = self
      %w(discard deck hand played constructs).each do |m|
        s.send(m).side = s
      end
      s.choices.each do |c|
        c.side = s
      end
    end

    card_places.each do |cards|
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
      game.sides << Side.new(:game => game)

      game.deck = CenterDeck.starting
      #game.deck << Parse.get("Mephit")
      game.center.fill!
      #side.deck << game.deck.get_one('Temple Librarian')
      #side.deck[-1] = Card::Hero.arha

      side.deck << Parse.get("Temple Librarian")

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

class Side
  include FromHash
  setup_mongo_persist :discard, :deck, :hand, :played, :constructs, :honor, :side_id, :choices
  attr_accessor :game
  fattr(:discard) { Discard.new(:side => self) }
  fattr(:deck) { PlayerDeck.starting(:side => self) }
  fattr(:hand) { Hand.new(:side => self) }
  fattr(:played) { Played.new(:side => self) }
  fattr(:constructs) { Constructs.new(:side => self) }
  fattr(:honor) { 0 }
  fattr(:side_id) { rand(100000000000000) }
  fattr(:choices) { [] }

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
  def acquire_free(card)
    discard << card
    game.center_wc.remove(card)
    fire_event Event::CardPurchased.new(:card => card)
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
    puts "in other side, this side is #{side_id} and other side is #{res.side_id}"
    res
  end
  def print_status!
    puts "Center " + game.center.to_s_cards
    puts "Hand " + hand.to_s_cards
    puts "Played " + played.to_s_cards
    puts "Constructs " + constructs.to_s_cards unless constructs.empty?
    puts "Pool " + played.pool.to_s
  end
end

%w(card cards ability pool events parse turn_manager setup_rchoice).each do |f|
  load File.dirname(__FILE__) + "/ascension/#{f}.rb"
end