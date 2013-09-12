require File.dirname(__FILE__) + "/spec_helper"

describe_engaged "Hoarding Tyrant" do
  adds_honor 4
  adds_no_runes
  has_no_choice
  has_trophy

  describe_played_trophy do
    adds_runes 2
    adds_honor 4
  end
end

describe_engaged "Hoarding Whelp" do
  let(:pool_power) { 3 }
  adds_honor 2
  has_trophy

  describe_played_trophy do
    adds_power -2
    adds_honor 2
  end
end

describe_engaged "Wind Tyrant" do
  adds_honor 3
  adds_runes 3
  has_no_choice
  has_no_trophy
end

describe_engaged "Minotaur" do
  adds_honor 3
  adds_cards 0
  has_trophy

  describe_played_trophy do
    adds_cards 1
  end
end


