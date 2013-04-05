require File.dirname(__FILE__) + "/spec_helper"

describe "ChoiceInstance" do
  before do
    $playing_on_command_line = false
  end

  after do
    $playing_on_command_line = true
  end

  let(:unsaved_shado) do
    Parse.get("Shade ot Black Watch")
  end
  let(:unsaved_game) do
    res = Game.new
    res.sides << Side.new(:game => res)
    res.center.fill!
    res
  end
  let(:unsaved_side) do
    res = unsaved_game.sides.first
    res.deck.cards =  res.deck.sort_by { |x| x.name } + [unsaved_shado]
    res.draw_hand!
    res
  end

  it 'smoke' do
    2.should == 2
  end

  describe "Basic" do
    let(:game) { unsaved_game }
    let(:side) { unsaved_side }

    it "stuff" do
      side.play unsaved_shado
      side.choices.size.should == 1
      side.choices.first.choosable_cards.size.should == 4
    end

    it 'hand cards' do
      side.hand.map { |x| x.name }.should == ["Shade ot Black Watch","Militia","Militia","Apprentice","Apprentice"]
    end
  end

  describe "full" do
    let(:game) do
      unsaved_side.play unsaved_shado
      unsaved_game.mongo.save!
      unsaved_game.mongo.get_fresh
    end
    let(:side) do
      game.sides.first
    end
    let(:choice) do
      side.choices.first
    end
    let(:chosen_card) do
      side.hand.first
    end

    it 'smoke' do
      side.choices.size.should == 1
      choice.choosable_cards.size.should == 4
      side.hand.size.should == 4
    end

    it 'choose' do
      choice.execute! chosen_card
      side.hand.size.should == 3
    end

    describe "with seer" do
      let(:unsaved_shado) do
        Parse.get("Seer of the Forked Path")
      end

      it 'seer abilities' do
        unsaved_shado.abilities.size.should == 2
      end

      it 'smoke' do
        side.choices.size.should == 1
        choice.choosable_cards.size.should == 6
        side.hand.size.should == 5
      end

    end

  
  end

  
end


