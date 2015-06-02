require 'test_helper'

describe Ramverk::Application do
  before(:each) { MockApp = Class.new(Ramverk::Application) }
  after(:each) { Object.send :remove_const, :MockApp }

  describe '.use' do
    it 'is a short-hand for middleware.use' do
      MockApp.use Rack::Head
      MockApp.middleware.stack.must_include [Rack::Head, [], nil]
    end
  end

  describe '.configure' do
    it 'does not set configuration if environment does not match' do
      MockApp.config[:raise_errors] = true
      MockApp.configure :production do
        config[:raise_errors] = false
      end
      MockApp.config[:raise_errors].must_equal true
      MockApp.configure :development, :test do
        config[:raise_errors] = false
      end
      MockApp.config[:raise_errors].must_equal false
    end
  end

  describe '.map' do
    before(:each) { MockRouter = Class.new(Ramverk::Router) }
    after(:each) { Object.send :remove_const, :MockRouter }

    it 'adds routers to the stack' do
      MockApp.map '/admin', MockRouter
      MockApp.routers.stack.must_include MockRouter
    end
  end

  describe '#call' do
    before(:each) do
      MockRouter = Class.new(Ramverk::Router) do
        get '/hello', :hello
        def hello
          raise ArgumentError, "Boom!"
        end
      end
    end

    after(:each) { Object.send :remove_const, :MockRouter }

    it 'raises errors if raise_errors is true' do
      MockApp.config[:raise_errors] = true
      MockApp.map MockRouter
      ->{ MockApp.new.call(rack_env('http://lolcahost:9292/hello')) }.must_raise ArgumentError
    end

    it 'does not raises errors if raise_errors is false (default)' do
      MockApp.config[:raise_errors] = false
      MockApp.map MockRouter
      res = MockApp.new.call(rack_env('http://lolcahost:9292/hello'))
      res[0].must_equal 500
    end
  end
end