require 'test_helper'

describe Ramverk::Router do
  describe '.error' do
    it 'recues the raises exception' do
      builder = Ramverk::Builder.new
      builder.map TestErrorsParentRouter
      builder.load!(Class.new(Ramverk::Application))

      req = Rack::MockRequest.new(builder)
      res = req.get('/test')
      res.status.must_equal 500
    end
  end
end
