require 'test_helper'

describe Ramverk::Router do
  describe '.route' do
    it 'sets up all the routes and includes the root' do
      TestRouter.routes.size.must_equal 2
      TestRouter.routes.last.path.must_equal '/:id'
    end

    it 'inherit routes' do
      TestParentRouter.routes.size.must_equal 4
      TestRouter.routes.size.must_equal 2
    end

    it 'raises NameError if action name is reserved' do
      ->{ TestRouter.get('/hello', :request) }.must_raise NameError
    end
  end

  describe 'initialize methods' do
    it 'sets upp instance variables for public methods' do
      ctrl = TestRouter.new(rack_request('/blog'))
      ctrl.request.is_a?(Rack::Request).must_equal true
      ctrl.req.is_a?(Rack::Request).must_equal true
      ctrl.response.is_a?(Ramverk::Response).must_equal true
      ctrl.res.is_a?(Ramverk::Response).must_equal true
      ctrl.params.is_a?(Hash).must_equal true
      ctrl.params.must_equal ctrl.request.params
    end
  end

  describe '#process_route' do
    it 'raises NoActionError if method is not found' do
      ->{
        route = TestParentRouter.routes[2]
        TestParentRouter.new(rack_request('/blog')).process_route(route)
      }.must_raise Ramverk::Router::NoActionError
    end

    it 'stores the matched route' do
      route  = TestRouter.routes[0]
      router = TestRouter.new(rack_request('/'))
      router.route.must_equal nil
      router.process_route(route)
      router.route.must_equal route
    end
  end
end
