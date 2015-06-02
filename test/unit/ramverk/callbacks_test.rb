require 'test_helper'

require 'ramverk/callbacks'

describe Ramverk::Callbacks do
  before(:each) do
    MockRouter = Class.new(Ramverk::Router) do
      include Ramverk::Callbacks

      before :stop

      get '/', :index
      def index
        res.write 'Hello World'
      end

      def stop
        res.write('stop')
      end
    end
    MockParentRouter = Class.new(MockRouter) do
      skip_before :stop, only: :hit

      get '/stopped', :stopped
      def stopped
        res.write 'stopped'
      end
      get '/hit', :hit
      def hit
        res.write 'hit'
      end
    end
  end

  after(:each) do
    Object.send :remove_const, :MockRouter
    Object.send :remove_const, :MockParentRouter
  end

  let(:routers) { Ramverk::Routers.new }

  it 'runs the before filter and stop execution if a response has been rendered' do
    routers.map MockRouter
    routers.map MockParentRouter
    routers.load!

    req = Rack::MockRequest.new(routers)
    res = req.get('/')
    res.body.must_equal 'stop'
  end

  it 'skips certain callbacks if defined on skip:only' do
    routers.map MockRouter
    routers.map MockParentRouter
    routers.load!

    req = Rack::MockRequest.new(routers)
    res = req.get('/stopped')
    res.body.must_equal 'stop'

    req = Rack::MockRequest.new(routers)
    res = req.get('/hit')
    res.body.must_equal 'hit'
  end
end
