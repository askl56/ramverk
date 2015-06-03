class TestRackRouter < Ramverk::Router
  get '/test', :test
  def test
    res.write 'Hello World'
  end
end

class TestRackApplication < Ramverk::Application
  config[:raise_errors] = true
  map TestRackRouter
end
