require 'test_helper'

describe Ramverk::Router do
  before(:each) do
    MockRouter = Class.new(Ramverk::Router) do
      get '/', :index
      def index
        res.write 'Hello World'
      end
      get '/:id', :show
      def show
        res.write "post-#{params['id']}"
      end
    end
    MockParentRouter = Class.new(MockRouter) do
      get '/unknown', :unknown
      post '', :create
      def create
      end
    end
  end

  after(:each) do
    Object.send :remove_const, :MockRouter
    Object.send :remove_const, :MockParentRouter
  end

  describe '.route' do
    it 'sets up all the routes and includes the root' do
      MockRouter.routes.size.must_equal 2
      MockRouter.routes.last.path.must_equal '/:id'
    end

    it 'inherit routes' do
      MockParentRouter.routes.size.must_equal 4
      MockRouter.routes.size.must_equal 2
    end

    it 'raises NameError if action name is reserved' do
      ->{ MockRouter.get('/hello', :request) }.must_raise NameError
    end
  end

  describe 'initialize methods' do
    it 'sets upp instance variables for public methods' do
      ctrl = MockRouter.new(rack_request('/blog'))
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
        route = MockParentRouter.routes[2]
        MockParentRouter.new(rack_request('/blog')).process_route(route)
      }.must_raise Ramverk::Router::NoActionError
    end

    it 'stores the matched route' do
      route  = MockRouter.routes[0]
      router = MockRouter.new(rack_request('/'))
      router.route.must_equal nil
      router.process_route(route)
      router.route.must_equal route
    end
  end
end
