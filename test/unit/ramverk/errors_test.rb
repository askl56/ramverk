require 'test_helper'

describe Ramverk::Router do
  describe '.error' do
    it 'recues the raises exception' do
      routers = Ramverk::Routers.new
      routers.map TestErrorsParentRouter
      routers.load!
      req = Rack::MockRequest.new(routers)
      res = req.get('/test')
      res.status.must_equal 500
    end
  end
end
