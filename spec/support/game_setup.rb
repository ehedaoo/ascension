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

  let(:pool_power) { 0 }

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
    (hand_cards + cards_to_play).uniq.each { |c| res.deck << Parse.get(c) }
    res.draw_hand!
    res.played.pool.power += pool_power
    cards_to_play.each do |name|
      c = res.hand.find { |x| x.name == name } 
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
    res = game.sides.last
    res.draw_hand!
    res
  end

  let(:choice) do
    raise "wrong number of choices #{side.choices.size}" unless side.choices.size == 1
    side.choices.first
  end

  def choose_card(card,other=false)
    card = Parse.get(card) if card.kind_of?(String)
    (other ? side.other_side.choices.first : choice).execute! card
  end

  def add_to_hand_and_play(name)
    card = Parse.get(name)
    side.hand << card
    side.play(card)
  end

end