class TurnManager
  include FromHash
  setup_mongo_persist :current_side_index
  attr_accessor :game
  fattr(:current_side_index) { 0 }
  def current_side
    game.sides[current_side_index]
  end
  def advance!
    current_side.end_turn!
    self.current_side_index = current_side_index + 1
    self.current_side_index = 0 if current_side_index >= game.sides.size
  end
end