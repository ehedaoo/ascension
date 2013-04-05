load "lib/ascension.rb"

def db
  Mongo::Connection.new.db('ascension')
end

Ability::CardChoice.chooser = RChoice::CommandLineChooser.new

def setup_game!
  game = Game.new
  side = Side.new(:game => game)
  game.sides << side

  game.deck = CenterDeck.starting
  game.center.fill!
  side.deck << game.deck.get_one('Temple Librarian')
  #side.deck[-1] = Card::Hero.arha
  side.draw_hand!
  side.hand << game.deck.get_one('Void Thirster')
  side.deck << game.deck.get_one('Void Initiate')

  game.mongo.save!
end

#puts d.cards.inspect
#puts d.to_mongo_hash.inspect
#puts d.cards.to_mongo_hash.inspect

#Game.collection.remove
#setup_game!

game = Game.collection.find_one_object

side = game.sides.first

side.hand.play_all!

side.print_status!

Ability::DoCenterAction.new.call_until_nil(side) { side.print_status! }

side.end_turn!

game.mongo.save!