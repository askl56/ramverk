require 'test_helper'

describe Ramverk::Middleware do
  let(:middleware) { Ramverk::Middleware.new }

  describe '#use' do
    it 'adds a middleware into the stack' do
      middleware.use Rack::Head
      middleware.stack.must_include [Rack::Head, [], nil]
    end

    it 'allows arguments' do
      middleware.use Rack::ETag, 'max-age=0, private, must-revalidate'
      middleware.stack.must_include [Rack::ETag, ['max-age=0, private, must-revalidate'], nil]
    end

    it 'allows blocks' do
      block = ->{ }
      middleware.use Rack::BodyProxy, &block
      middleware.stack.must_include [Rack::BodyProxy, [], block]
    end
  end

  describe 'with session enabled' do
    before(:each) { MockApp = Class.new(Ramverk::Application) }
    after(:each)  { Object.send :remove_const, :MockApp }

    it 'rasies an error if session middleware is not enabled' do
      MockApp.config.security[:session_hijacking] = true
      ->{ middleware.load!(MockApp) }.must_raise RuntimeError
    end

    it 'enables session hijacking middleware' do
      MockApp.config[:session] = { secret: '<secret>' }
      MockApp.config.security[:session_hijacking] = true
      middleware.load!(MockApp)
      middleware.stack.must_include [Rack::Protection::SessionHijacking, [], nil]
    end
  end
end
