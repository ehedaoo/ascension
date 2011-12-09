class Array
  def reduce(*args,&b)
    inject(*args,&b)
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'rspec'
require 'rr'
#require 'choice'
require File.dirname(__FILE__) + "/../lib/ascension"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rr
end

def new_game_with_side
  game = Game.new
  side = Side.new(:game => game)
  game.sides << side
  [game,side]
end

def new_game_with_sides
  game = Game.new
  side = Side.new(:game => game)
  game.sides << side
  other = Side.new(:game => game)
  game.sides << other
  [game,side]
end

class CenterDeck
  def self.starting
    res = CenterDeck.new
    100.times { res << Card::Hero.standin }
    res
  end
end
