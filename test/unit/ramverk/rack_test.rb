require 'test_helper'

describe Ramverk::Application do
  before do
    MockApp = Class.new(Ramverk::Application) do
      config[:raise_errors] = true
    end
    MockRouter = Class.new(Ramverk::Router) do
      get '/test', :test
      def test
        res.write 'Hello World'
      end
    end
    MockApp.map MockRouter
  end

  after do
    Object.send :remove_const, :MockApp
    Object.send :remove_const, :MockRouter
  end

  it 'executed the request' do
    req = Rack::MockRequest.new(MockApp.new)
    res = req.get('/test')
    res.ok?.must_equal true
    res.body.must_equal 'Hello World'
  end
end
