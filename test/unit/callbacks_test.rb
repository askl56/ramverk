require 'test_helper'

describe Ramverk::Router do
  let(:app) { TestApplication }

  it 'runs the before filter and stop execution if a response has been rendered' do
    app.map TestCallbacksRouter
    app.map TestCallbacksParentRouter
    app.load

    req = Rack::MockRequest.new(app)
    res = req.get('/')
    res.body.must_equal 'stop'
  end

  it 'skips certain callbacks if defined on skip:only' do
    app.map TestCallbacksRouter
    app.map TestCallbacksParentRouter
    app.load

    req = Rack::MockRequest.new(app)
    res = req.get('/stopped')
    res.body.must_equal 'stop'

    req = Rack::MockRequest.new(app)
    res = req.get('/hit')
    res.body.must_equal 'hit'
  end

  it 'skips all if none of only and except is set' do
    app.map TestSkipParentCallbacksRouter
    app.load
    req = Rack::MockRequest.new(app)
    res = req.get('/')
    res.body.must_equal 'nonstop'
  end
end
