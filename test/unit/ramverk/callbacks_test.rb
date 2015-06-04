require 'test_helper'

describe Ramverk::Router do
  let(:builder) { Ramverk::Builder.new }

  it 'runs the before filter and stop execution if a response has been rendered' do
    builder.map TestCallbacksRouter
    builder.map TestCallbacksParentRouter
    builder.load!(Class.new(Ramverk::Application))

    req = Rack::MockRequest.new(builder)
    res = req.get('/')
    res.body.must_equal 'stop'
  end

  it 'skips certain callbacks if defined on skip:only' do
    builder.map TestCallbacksRouter
    builder.map TestCallbacksParentRouter
    builder.load!(Class.new(Ramverk::Application))

    req = Rack::MockRequest.new(builder)
    res = req.get('/stopped')
    res.body.must_equal 'stop'

    req = Rack::MockRequest.new(builder)
    res = req.get('/hit')
    res.body.must_equal 'hit'
  end

  it 'skips all if none of only and except is set' do
    builder.map TestSkipParentCallbacksRouter
    builder.load!(Class.new(Ramverk::Application))
    req = Rack::MockRequest.new(builder)
    res = req.get('/')
    res.body.must_equal 'nonstop'
  end
end
