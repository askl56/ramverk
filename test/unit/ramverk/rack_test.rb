require 'test_helper'

describe Ramverk::Application do
  it 'executed the request' do
    req = Rack::MockRequest.new(TestRackApplication.new)
    res = req.get('/test')
    res.ok?.must_equal true
    res.body.must_equal 'Hello World'
  end
end
