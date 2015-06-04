require 'test_helper'

describe Ramverk::Router do
  let(:routers) { Ramverk::Routers.new }

  it 'runs the before filter and stop execution if a response has been rendered' do
    routers.map TestCallbacksRouter
    routers.map TestCallbacksParentRouter
    routers.load!

    req = Rack::MockRequest.new(routers)
    res = req.get('/')
    res.body.must_equal 'stop'
  end

  it 'skips certain callbacks if defined on skip:only' do
    routers.map TestCallbacksRouter
    routers.map TestCallbacksParentRouter
    routers.load!

    req = Rack::MockRequest.new(routers)
    res = req.get('/stopped')
    res.body.must_equal 'stop'

    req = Rack::MockRequest.new(routers)
    res = req.get('/hit')
    res.body.must_equal 'hit'
  end

  it 'skips all if none of only and except is set' do
    routers.map TestSkipParentCallbacksRouter
    routers.load!
    req = Rack::MockRequest.new(routers)
    res = req.get('/')
    res.body.must_equal 'nonstop'
  end
end
