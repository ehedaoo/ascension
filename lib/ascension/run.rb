require 'rubygems'
require 'lib/ascension'

game = Game.new
side = Side.new(:game => game)
game.sides << side

game.deck = CenterDeck.starting
game.center.fill!
side.draw_hand!

side.print_status!

side.hand.play_all!

side.print_status!

Ability::CardChoice.chooser = Choice::CommandLineChooser.new

Ability::BanishCenter.new.call(side)

side.print_status!