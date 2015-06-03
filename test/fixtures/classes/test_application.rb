class TestApplicationRouter < Ramverk::Router
  get '/hello', :hello
  def hello
    raise ArgumentError, "Boom!"
  end
end

class TestApplication < Ramverk::Application
  map TestApplicationRouter
end