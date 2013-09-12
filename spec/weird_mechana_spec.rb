require File.dirname(__FILE__) + "/spec_helper"

describe_construct_invoked "The All Seeing Eye" do
  adds_cards 1
end

describe_construct_invoked "Dream Machine", :constructs => ['Rocket Courier X-99'] do
  let(:cards_to_play) { ['Burrower Mk II'] }
  adds_cards 0
  has_choice 1, :choosable_cards => 2

  has_constructs "Dream Machine","Rocket Courier X-99","Burrower Mk II"

  with_choice "Burrower Mk II" do
    has_constructs "Dream Machine","Rocket Courier X-99"
    hand_includes "Burrower Mk II"

    describe "replay burrower" do
      play_card "Burrower Mk II"
      has_constructs "Dream Machine","Rocket Courier X-99","Burrower Mk II"

      adds_cards 1
    end
  end
end

describe_played "Great-Omen Raven" do
  has_choice 1, :choosable_cards => 3
  describe 'after choice' do
    before do
      card = side.deck.last
      choose_card card.name
    end
    adds_cards 0
    adds_honor 3
  end
end

describe_construct_invoked "Black Hole" do
  has_choice 1, :choosable_cards => 5
end