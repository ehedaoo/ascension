class Array
  def sum
    inject { |s,i| s + i }
  end
end

class Object
  def klass
    self.class
  end
end

class Array
  def uniq_by
    res = {}
    each do |obj|
      res[yield(obj)] ||= obj
    end
    res.values
  end
end