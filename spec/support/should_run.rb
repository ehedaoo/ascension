class ShouldRun
  def self.run?(desc,*args)
    return true
    desc == 'has invokeable ability'
  end

  class << self
    def file?(file)
      skip = %w(choice_instance_spec.rb)
      base = File.basename(file)
      return false if skip.include?(base)
      true
    end
  end
end