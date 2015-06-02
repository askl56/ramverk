require 'test_helper'

describe Ramverk::Router do
  before(:each) do
    MockRouter = Class.new(Ramverk::Router) do
      error ArgumentError, :error_500
      def error_500(e = nil)
        res.status(500).write('[500] Kaboom!')
      end
    end
    MockParentRouter = Class.new(MockRouter) do
      get '/test', :test
      def test
        raise ArgumentError, "Boom!"
      end
    end
  end

  after(:each) do
    Object.send :remove_const, :MockRouter
    Object.send :remove_const, :MockParentRouter
  end

  describe '.error' do
    it 'recues the raises exception' do
      routers = Ramverk::Routers.new
      routers.map MockParentRouter
      routers.load!
      req = Rack::MockRequest.new(routers)
      res = req.get('/test')
      res.status.must_equal 500
    end
  end
end
