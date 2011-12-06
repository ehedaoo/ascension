class Pool
  include FromHash
  fattr(:runes) { 0 }
  fattr(:mechana_runes) { 0 }
  fattr(:power) { 0 }
  def use_rune_type(type, max)
    pool = send(type)
    if max >= pool
      send("#{type}=",0)
      max - pool
    else
      send("#{type}=",pool - max)
      0
    end
  end
  def deplete_runes(card)
    remaining = card.rune_cost
    if card.mechana?
      remaining = use_rune_type(:mechana_runes,remaining)
    end
    if remaining > 0
      remaining = use_rune_type(:runes,remaining)
    end
    raise "not enough runes" if remaining > 0
  end
end