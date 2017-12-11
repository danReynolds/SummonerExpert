module Utils
  def dig_set(*keys)
    hash = {}
    key = keys.shift
    return key if keys.empty?

    hash[key] = dig_set(*keys)
    hash
  end

  def dig_list(obj)
    return [] if obj.empty?
    if obj.class == Hash
      key = obj.keys.first
      [key] + dig_list(obj[key])
    else
      [obj]
    end
  end
end
