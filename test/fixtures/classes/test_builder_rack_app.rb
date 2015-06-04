class TestBuilderRackApplication
  def self.call(env)
    [200, {}, ['hello from rack']]
  end
end
