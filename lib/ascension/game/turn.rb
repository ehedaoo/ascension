class Turn
  include FromHash
  fattr(:engaged_cards) { [] }
  fattr(:played_cards) { [] }
  setup_mongo_persist :engaged_cards, :played_cards

  def as_json
    #puts "turn as_json"
    {}
  end
end
