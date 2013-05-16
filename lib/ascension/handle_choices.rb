module HandleChoices
  def handle_choices!
    sides.each do |side|
      side.choices.each do |choice|
        if side.ai
          side.ai.handle_choice(choice) 
        else
          return false
        end
      end
    end
    true
  end
end