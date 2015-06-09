class JSONObject1
  def as_json(opts = {})
    { name: 'first' }
  end
end

class JSONObject2
  def as_json(opts = {})
    { name: 'second' }
  end
end
