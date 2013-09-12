require File.dirname(__FILE__) + "/spec_helper"

describe_played "Abolisher" do
  adds_runes 1
  has_choice
  has_hand 4


  with_choice "Apprentice" do
    has_hand 3
    adds_runes 2
    has_no_choice
  end

  with_choice nil do
    has_hand 4
    adds_runes 1
    has_no_choice
  end
end