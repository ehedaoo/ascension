class AbilityTracker
  include FromHash
  attr_accessor :side

  fattr(:counts) do
    Hash.new { |h,k| h[k] = 0 }
  end

  def count(obj)
    counts[obj]
  end
  def inc(obj)
    counts[obj] += 1
  end
end
