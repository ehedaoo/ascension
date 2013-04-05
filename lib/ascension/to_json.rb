require 'json'
module JsonPersist
  def as_json(*args)
    to_json_hash
  end
  def new_hash_json(attr,h,obj)
    if obj.can_mongo_convert?
      if obj.respond_to?(:select) && false
        h.merge(attr => obj.to_mongo_hash)
      elsif [Numeric,String].any? { |c| obj.kind_of?(c) }
        h.merge(attr => obj)
      else
        h.merge(attr => obj.as_json) 
      end
    else
      h
    end
  rescue
    return h
  end
  def to_json_hash
    res = mongo_child_attributes.inject({}) do |h,attr| 
      obj = send(attr)
      #raise "#{attr} is nil" unless obj
      new_hash_json(attr,h,obj)
    end.merge("_mongo_class" => self.class.to_s)
    klass.mongo_reference_attributes.each do |attr|
      val = send(attr)
      res[attr] = val.to_mongo_ref_hash if val
    end

    if respond_to?(:addl_json_attributes) && true
      puts "in addl_json_attributes part"
      addl = [addl_json_attributes].flatten.select { |x| x }
      addl.each do |attr|
        puts "addl attr #{attr}"
        res = new_hash_json(attr,res,send(attr))
      end
    end
    res
  end
  def to_json(*args)
    as_json(*args).to_json
  end
end

module MongoHash
  def as_json(*args)
    res = {}
    each do |k,v| 
      v = v.as_json(*args) if v.respond_to?(:as_json)
      res[k.safe_to_mongo_hash.to_mongo_key] = v
    end
    res
  end
end

class Array
  def as_json(*args)
    map do |obj|
      obj.respond_to?(:as_json) ? obj.as_json(*args) : obj
    end
  end
end

class Class
  def setup_mongo_persist(*attrs)
    include MongoPersist
    include JsonPersist
    define_method(:mongo_attributes) do
      attrs.flatten.map { |x| x.to_s }
    end
  end
end