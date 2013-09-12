require File.dirname(__FILE__) + "/spec_helper"

describe_played "Askara of Fate" do
  adds_honor 0
  adds_cards 1
  adds_cards 1, :other_side
  has_choice 1, :choosable_cards => 6
end

describe_center "Askara of Fate" do
  adds_cards 1
  adds_cards 1, :other_side
end