class Debug
  class << self
    def log(*args)
      #puts args.join(",")
      File.append "debug.log","#{args.first}\n"
    end
    def clear!
      File.create("debug.log","Starting Log at #{Time.now}\n")
    end
  end
end