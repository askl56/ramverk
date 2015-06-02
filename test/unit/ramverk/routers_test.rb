require 'test_helper'

class TestRoutersRouter < Ramverk::Router
  get '/', :index
  def index
    res.write('hello')
  end
end

class TestRouters2Router < Ramverk::Router
  get '/say/:word', :say
  def say
    res.write(params['word'])
  end
end

class NoResponseTestRouter < Ramverk::Router
  post '/', :create
  def create
  end
end

describe Ramverk::Routers do
  let(:routers) { Ramverk::Routers.new }

  it 'raises RuntimeError if no response is sent' do
    routers.map '/blog', NoResponseTestRouter
    routers.load!
    req = Rack::MockRequest.new(routers)
    ->{ req.post('/blog') }.must_raise RuntimeError
  end

  describe '#map' do
    it 'adds a new controller to the stack' do
      routers.map TestRoutersRouter, TestRouters2Router
      routers.stack.size.must_equal 2
    end

    it 'prepends a root' do
      TestRoutersRouter.routes[0].path.must_equal '/'
      routers.map '/admin', TestRoutersRouter
      routers.load!
      TestRoutersRouter.routes[0].path.must_equal '/admin'
    end
  end

  describe '.call' do
    before(:each) do
      routers.map TestRouters2Router
      routers.load!
    end

    it 'processes requests with #call' do
      routers.respond_to?(:call).must_equal true

      req = Rack::MockRequest.new(routers)
      res = req.get('/say/hello')
      res.ok?.must_equal true
      res.body.must_equal 'hello'
    end

    it 'returns 404 if no routers is found' do
      req = Rack::MockRequest.new(routers)
      res = req.get('/foo/bar/baz/qux')
      res.status.must_equal 404
      res.body.must_equal 'Not Found'
    end
  end
end
