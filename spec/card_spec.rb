require File.dirname(__FILE__) + "/spec_helper"

describe "card" do
  describe "ascetic" do
    let(:unsaved_ascetic) do
      Parse.get("Ascetic of the Lidless Eye")
    end
    let(:unsaved_game) do
      res = Game.new
      res.sides << Side.new
      res.center.fill!
      res
    end
    let(:unsaved_side) do
      res = unsaved_game.sides.first
      res.draw_hand!
      res.hand << unsaved_ascetic
      res
    end

    describe "basic" do
      let(:game) { unsaved_game }
      let(:side) { unsaved_side }
      let(:ascetic) { unsaved_ascetic }

      it 'smoke' do
        side.hand.size.should == 6
      end

      it 'playing ascetic' do
        side.play ascetic
        side.played.size.should == 1
        side.hand.size.should == 7
      end
    end

    if true
      describe "after save" do
        let(:game) do
          unsaved_game
          unsaved_side
          unsaved_game.mongo.save!
          unsaved_game.mongo.get_fresh
        end

        let(:side) do
          game.sides.first
        end

        let(:ascetic) do
          side.hand.find { |x| x.name == "Ascetic of the Lidless Eye" }
        end

        it 'hydrate smoke' do
          side.hand.size.should == 6
        end

        it 'hydrate' do
          side.play ascetic
          side.played.size.should == 1
          side.hand.size.should == 7
        end
      end
    end

    describe "hydrated card" do
      let(:raw_ascetic) do
        Card::Hero.new(:name => "Ascetic of the Lidless Eye")
      end
      let(:hydrated_ascetic) do
        raw_ascetic.hydrated
      end

      it 'has abilities' do
        hydrated_ascetic.abilities.size.should == 1
      end

      it 'has same card id' do
        hydrated_ascetic.card_id.should == raw_ascetic.card_id
      end

      it 'foo' do
        #raise Parse.get("Shade ot Black Watch").abilities.inspect
      end
    end
  end
end