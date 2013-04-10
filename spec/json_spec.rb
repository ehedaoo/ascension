require File.dirname(__FILE__) + "/spec_helper"

describe 'card json' do
  let(:card) do
    Card::Construct.new(:name => "Some Card", :invokable_abilities => [14])
  end
  it 'has card id' do
    card.as_json['card_id'].should == card.card_id
  end
  it 'has invokable ability' do
    card.as_json['has_invokable_ability'].should == true
  end

end