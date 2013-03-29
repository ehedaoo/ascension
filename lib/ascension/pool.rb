class Pool
  include FromHash
  fattr(:runes) { 0 }
  fattr(:mechana_runes) { 0 }
  fattr(:construct_runes) { 0 }
  fattr(:power) { 0 }
  def use_rune_type(type, max, modify=true)
    raise "bad max" unless max
    pool = send(type)
    if max >= pool
      send("#{type}=",0) if modify
      max - pool
    else
      send("#{type}=",pool - max) if modify
      0
    end
  end
  def can_purchase?(card)
    remaining = card.rune_cost
    raise "bad rune cost #{card.name}" unless remaining
    if card.mechana? && card.construct?
      remaining = use_rune_type(:mechana_runes,remaining,false)
    end
    if card.construct?
      remaining = use_rune_type(:construct_runes,remaining,false)
    end
    if remaining > 0
      remaining = use_rune_type(:runes,remaining,false)
    end
    remaining == 0
  end
  def deplete_runes(card)
    remaining = card.rune_cost
    if card.mechana? && card.construct?
      remaining = use_rune_type(:mechana_runes,remaining)
    end
    if card.construct?
      remaining = use_rune_type(:construct_runes,remaining)
    end
    if remaining > 0
      remaining = use_rune_type(:runes,remaining)
    end
    raise "not enough runes" if remaining > 0
  end
  def to_s
    "#{runes} (#{mechana_runes}) / #{power}"
  end
end