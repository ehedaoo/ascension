Parse.reg_word :lifebound_hero_played do |event|
  event.kind_of?(Event::CardPlayed) && event.card.realm.to_s == 'lifebound' && event.card.kind_of?(Card::Hero)
end

Parse.reg_word :mechana_construct_played do |event|
  event.kind_of?(Event::CardPlayed) && event.card.realm.to_s == 'mechana' && event.card.kind_of?(Card::Construct)
end

Parse.reg_word :center_monster_killed do |event|
  event.kind_of?(Event::MonsterKilled) && event.center
end

Parse.reg_word :two_or_more_constructs do |side,junk|
  side.constructs.size >= 2
end

Parse.reg_word :count_of_mechana_constructs do |side,*args|
  side.constructs.select { |x| x.mechana? }.size
end

Parse.reg_word :type_of_construct do |side,*args|
  side.constructs.map { |x| x.realm }.uniq.size
end

(2..6).each do |i|
  Parse.reg_ability "kill_monster_#{i}", Ability::KillMonster.new(:max_power => i)
end

(1..10).each do |i|
  Parse.reg_ability "acquire_hero_#{i}", Ability::AcquireHero.new(:max_rune_cost => i)
end

Parse.reg_ability :discard_construct, Ability::DiscardConstruct.new
Parse.reg_ability :discard_all_but_one_construct, Ability::KeepOneConstruct.new

Parse.reg_ability :copy_hero, Ability::CopyHero.new

Parse.reg_ability :acquire_center, Ability::AcquireCenter.new

Parse.reg_ability :take_opponents_card, Ability::TakeOpponentsCard.new

Parse.reg_ability :acquire_construct, Ability::AcquireConstruct.new

Parse.reg_ability :return_mechana_construct_to_hand, Ability::ReturnMechanaConstructToHand.new

Parse.reg_ability :guess_top_card_for_3, Ability::GuessTopCardFor3.new

Parse.reg_ability :upgrade_hero_in_hand, Ability::UpgradeHeroInHand.new

%w(power_or_rune_1 take_opponents_casrd acquire_centerx).each do |f|
  Parse.reg_ability f do |*args|
  end
end
