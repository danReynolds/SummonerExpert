module Utils
  def dig_set(keys)
    hash = {}
    key = keys.shift
    return key if keys.empty?

    hash[key] = dig_set(keys)
    hash
  end
end
