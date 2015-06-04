require 'test_helper'

describe Ramverk::Builder do
  let(:builder) { Ramverk::Builder.new }

  describe '#use' do
    it 'adds a middleware into the middleware' do
      builder.use Rack::Head
      builder.middleware.must_include [Rack::Head, [], nil]
    end

    it 'allows arguments' do
      builder.use Rack::ETag, 'max-age=0, private, must-revalidate'
      builder.middleware.must_include [Rack::ETag, ['max-age=0, private, must-revalidate'], nil]
    end

    it 'allows blocks' do
      block = ->{ }
      builder.use Rack::BodyProxy, &block
      builder.middleware.must_include [Rack::BodyProxy, [], block]
    end
  end

  describe 'with session enabled' do
    it 'rasies an error if session middleware is not enabled' do
      TestMiddlewareApplication.config[:session] = false
      TestMiddlewareApplication.config.security[:session_hijacking] = true
      ->{ builder.load!(TestMiddlewareApplication) }.must_raise RuntimeError
    end

    it 'enables session hijacking middleware' do
      TestMiddlewareApplication.config[:session] = { secret: '<secret>' }
      TestMiddlewareApplication.config.security[:session_hijacking] = true
      builder.load!(TestMiddlewareApplication)
      builder.middleware.must_include [Rack::Protection::SessionHijacking, [], nil]
    end
  end

  describe '#map' do
    it 'adds a new router to the routers stack' do
      builder.map TestRoutersRouter, TestRouters2Router
      builder.routers.size.must_equal 2
    end

    it 'prepends a root' do
      TestRoutersRouter.routes[0].path.must_equal '/'
      builder.map '/admin', TestRoutersRouter
      builder.load!(Class.new(Ramverk::Application))
      TestRoutersRouter.routes[0].path.must_equal '/admin'
    end
  end

  it 'raises RuntimeError if no response is sent' do
    builder.map '/blog', TestNoResponseTestRouter
    builder.load!(Class.new(Ramverk::Application))
    req = Rack::MockRequest.new(builder)
    ->{ req.post('/blog') }.must_raise RuntimeError
  end

  describe '.call' do
    before(:each) do
      builder.map TestRouters2Router
      builder.load!(Class.new(Ramverk::Application))
    end

    it 'processes requests with #call' do
      builder.respond_to?(:call).must_equal true

      req = Rack::MockRequest.new(builder)
      res = req.get('/say/hello')
      res.ok?.must_equal true
      res.body.must_equal 'hello'
    end

    it 'returns 404 if no routers is found' do
      req = Rack::MockRequest.new(builder)
      res = req.get('/foo/bar/baz/qux')
      res.status.must_equal 404
      res.body.must_equal 'Not Found'
    end
  end

  describe 'mount rack apps' do
    it 'returns 404 if no routers is found' do
      builder.map TestRouters2Router
      builder.map '/rack', TestBuilderRackApplication
      builder.load!(Class.new(Ramverk::Application))

      req = Rack::MockRequest.new(builder)
      res = req.get('/rack/yeah')
      res.body.must_equal 'hello from rack'

      req = Rack::MockRequest.new(builder)
      res = req.get('/say/hello')
      res.ok?.must_equal true
      res.body.must_equal 'hello'
    end
  end
end
