require File.dirname(__FILE__) + "/spec_helper"

describe "center" do
  let(:game) do
    res = Game.new
    res.deck = CenterDeck.starting
    res.center.fill!
    res
  end
  let(:center) do
    game.center
  end

  it "has 6 cards" do
    center.size.should == 6
  end

  it 'should replace cards in same spot' do
    rest = center[1..-1]
    center.remove center[0]
    center[1..-1].should == rest
    center[0].should be
    center.size.should == 6
  end
end