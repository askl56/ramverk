require 'test_helper'

class MockRackRouter < Ramverk::Router
  get '/test', :test
  def test
    res.write 'Hello World'
  end
end

class MockRackApp < Ramverk::Application
  config[:raise_errors] = true
  map MockRackRouter
end

describe Ramverk::Application do
  it 'executed the request' do
    req = Rack::MockRequest.new(MockRackApp.new)
    res = req.get('/test')
    res.ok?.must_equal true
    res.body.must_equal 'Hello World'
  end
end
