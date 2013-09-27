module Parse
  def self.reg_word(word,&b)
    Words.instance.reg_word(word,&b)
  end
  def self.reg_ability(word,ability=nil,&b)
    ability ||= b
    Words.instance.reg_word(word,ability)
    #wWords.instance.reg_ability(word,ability)
  end
  def self.cards
    @cards ||= InputFile.new.cards
  end
  def self.reset!
    @card = nil
  end
  def self.get(name)
    res = cards.find { |x| x.name == name }.tap { |x| raise "no card #{name}" unless x }
    raise "invoked_ability" if res.respond_to?(:invoked_ability) && res.invoked_ability
    res.invoked_ability = false if res.respond_to?(:invoked_ability)
    res = res.clone
    res.abilities = res.abilities.map { |x| x.clone }
    res.triggers = res.triggers.map { |x| x.clone }
    res
  end
end