require 'rubygems'
load File.dirname(__FILE__) + '/../ascension.rb'

Ability::CardChoice.chooser = RChoice::CommandLineChooser.new

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

while true

  side.hand.play_all!

  side.print_status!

  Ability::DoCenterAction.new.call_until_nil(side) { side.print_status! }
  
  side.end_turn!
end