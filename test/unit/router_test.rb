require 'test_helper'

describe Ramverk::Router do
  describe '.route' do
    it 'inherit routers' do
      TestParentRouter.routes.size.must_equal 4
      TestRouter.routes.size.must_equal 2
    end

    it 'raises NameError if action name is reserved' do
      ->{ TestRouter.get('/hello', :request) }.must_raise NameError
    end
  end

  describe 'REST methods' do
    %w(GET POST PUT PATCH DELETE OPTIONS LINK UNLINK).each do |method|
      describe ".#{method.downcase}" do
        it "creates a #{method} route" do
          TestRESTRouter.send(method.downcase, '/', :index)
          TestRESTRouter.routes.last.methods.must_equal [method]
        end
      end
    end
  end

  describe '.match' do
    it 'collects the matched url params and merge them into request' do
      app = TestApplication
      app.map TestRouter
      app.load
      req = Rack::MockRequest.new(app)
      res = req.get('/54')
      res.body.must_equal 'post-54'
    end
  end

  describe 'initialize methods' do
    it 'sets upp instance variables for public methods' do
      ctrl = TestRouter.new(rack_request('/blog'), TestApplication)
      ctrl.request.is_a?(Rack::Request).must_equal true
      ctrl.req.is_a?(Rack::Request).must_equal true
      ctrl.response.is_a?(Ramverk::Response).must_equal true
      ctrl.res.is_a?(Ramverk::Response).must_equal true
      ctrl.params.is_a?(Hash).must_equal true
      ctrl.params.must_equal ctrl.request.params
      ctrl.app.must_equal TestApplication
    end
  end

  describe '#params' do
    it 'symbolize nested keys' do
      ctrl = TestRouter.new(rack_request('/test', 'GET', params: { user: { name: 'tobias' }}), TestApplication)
      ctrl.params.must_equal({user: {name: 'tobias'}})
    end
  end

  describe '#process_route' do
    it 'raises NoActionError if method is not found' do
      ->{
        route = TestParentRouter.routes[2]
        TestParentRouter.new(rack_request('/blog'), TestApplication).process_route(route)
      }.must_raise Ramverk::Router::NoActionError
    end

    it 'stores the matched route' do
      route  = TestRouter.routes[0]
      router = TestRouter.new(rack_request('/'), TestApplication)
      router.route.must_equal nil
      router.process_route(route)
      router.route.must_equal route
    end
  end
end
