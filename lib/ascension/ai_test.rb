require 'rubygems'
load File.dirname(__FILE__) + '/../ascension.rb'

$playing_on_command_line = false

#Ability::CardChoice.chooser = RChoice::CommandLineChooser.new

game = Game.new
game.sides << Side.new(:game => game)
game.sides << Side.new(:game => game)

game.deck = CenterDeck.starting
game.center.fill!

game.sides.each { |x| x.draw_hand! }

ais = game.sides.map do |side|
  side.ai = AI::Basic.new(:side => side)
end

while game.honor > 0
  ais.each do |ai|
    ai.play_turn!
    puts "\n\n\n"
  end
end