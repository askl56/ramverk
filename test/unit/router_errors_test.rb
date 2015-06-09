require 'test_helper'

describe Ramverk::Router do
  let(:app) { TestApplication }

  describe '.error' do
    it 'recues the raises exception' do
      app.map TestErrorsParentRouter
      app.load

      req = Rack::MockRequest.new(app)
      res = req.get('/test')
      res.status.must_equal 500
    end
  end
end
