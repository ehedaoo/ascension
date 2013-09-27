module Parse
  class Line
    include FromHash
    attr_accessor :raw
    attr_accessor :realm_short
    fattr(:card_class) do
      h = {'H' => ::Card::Hero, 'C' => ::Card::Construct, 'M' => ::Card::Monster}
      h[raw['card_type']] || (raise 'no class')
    end
    fattr(:realm) do
      h = {'L' => :lifebound, 'M' => :mechana, 'V' => :void, 'E' => :enlightened, 'S' => :monster}
      h[raw['realm_short']] || (raise 'no realm')
    end
    fattr(:parse_card) do
      card = Card.new
      %w(card_class realm).each do |f|
        card.send("#{f}=",send(f))
      end
      %w(name rune_cost honor runes power power_cost draw banish_center banish_hand_discard special_abilities discard_from_hand honor_given banish_hand runes_for_honor).each do |f|
        card.send("#{f}=",raw[f])
      end
      card
    end
    fattr(:cards) do
      raw['count'].to_i.of { parse_card.card! }
    end
  end
end