require File.dirname(__FILE__) + "/spec_helper"

describe "basic ai" do
  include_context "game setup"
  let(:ai) { AI::Basic.new(:side => side) }

  it 'smoke' do
    ai.play_turn!
    (side.discard.size >= 6).should be
  end
end