shared_context "game setup" do
  before do
    $playing_on_command_line = false
  end

  after do
    $playing_on_command_line = true
  end

  let(:center_cards) { [] }
  let(:hand_cards) { [] }
  let(:cards_to_play) { [] }
  let(:cards_to_engage) { [] }
  let(:constructs) { [] }

  let(:pool_power) { 0 }
  let(:pool_runes) { 0 }

  let(:game) do
    res = Game.new
    res.sides << Side.new(:game => res)
    res.sides << Side.new(:game => res)
    (center_cards + cards_to_engage).uniq.each { |c| res.deck << Parse.get(c) }
    res.center.fill!
    res
  end

  let(:side) do
    res = game.sides.first
    (hand_cards + cards_to_play).uniq.each do |c| 
      c = Parse.get(c) if c.kind_of?(String)
      res.deck << c
      raise "bad" if c.triggers.any? { |t| t.respond_to?(:body_count) && t.body_count > 0 }
    end
    res.draw_hand!
    res.played.pool.power += pool_power
    res.played.pool.runes += pool_runes
    constructs.each do |c|
      c = Parse.get(c) if c.kind_of?(String)
      res.constructs << c
    end

    cards_to_play.each do |name|
      c = name.kind_of?(String) ? res.hand.find { |x| x.name == name } : name
      raise "no card #{name}" unless c
      res.play(c) 
    end

    cards_to_engage.each do |name|
      c = game.center.find { |x| x.name == name }
      raise "no card #{name}" unless c
      res.engage(c)
    end

    res
  end

  let(:other_side) do
    game; side;
    res = game.sides.last
    res.draw_hand!
    res
  end

  let(:choice) do
    raise "wrong number of choices #{side.choices.size}" unless side.choices.size == 1
    side.choices.first
  end

  def get_card(card)
    return card unless card.kind_of?(String)
    game.card_places.each do |cards|
      res = cards.reverse.find { |x| x.name == card }
      return res if res
    end
    raise "no card found"
  end

  def choose_card(card,other=false)
    card = get_card(card)
    (other ? side.other_side.choices.first : side.choices.first).execute! card
  end

  def add_to_hand_and_play(name)
    card = Parse.get(name)
    side.hand << card
    side.play(card)
  end

  def play_card(name)
    card = side.hand.find { |x| x.name == name }
    side.play card
  end

  def play_trophy(name)
    card = side.trophies.find { |x| x.name == name }
    side.trophies.play(card)
  end

  def invoke_construct(name)
    card = side.constructs.find { |x| x.name == name.to_s }
    card.invoke_abilities(side)
  end

end