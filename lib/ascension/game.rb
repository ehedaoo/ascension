class Game
  include HandleChoices
  setup_mongo_persist :sides, :center, :void, :honor, :deck, :turn_manager
  def addl_json_attributes
    %w(mongo_id engageable_cards constant_cards current_side_index last_update_dt)
  end
  def restricted_json_attributes
    %w(deck void)
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

  def self.local_card_place_names
    [:deck,:center,:void]
  end
  def local_card_places
    klass.local_card_place_names.map { |x| send(x) }
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
      #game.sides << Side.ai(:game => game)
      game.sides << Side.new(:game => game)

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