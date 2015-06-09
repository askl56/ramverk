require 'test_helper'

describe Ramverk::Application do
  let(:app) { TestApplication }

  it 'starts with a clean slate' do
    app.onload.must_equal({ before: [], after: [] })
    app.middleware.must_equal []
    app.routers.must_equal []
  end

  describe '.reset' do
    it 'resets the state of the application to the defaults' do
      app.config.raise_errors true
      app.config.raise_errors.must_equal true
      app.use Rack::Head
      app.middleware.must_include [Rack::Head, [], nil]
      app.reset
      app.config.raise_errors.must_equal false
      app.middleware.must_equal []
    end
  end

  describe '.configure' do
    it 'executes the block if the environment matches the active one' do
      app.config.raise_errors true
      app.configure :production do |app|
        app.config.raise_errors false
      end
      app.config.raise_errors.must_equal true
      app.configure :development, :test do |app|
        app.config.raise_errors false
      end
      app.config.raise_errors.must_equal false
    end
  end

  describe '.map' do
    it 'adds a new router to the routers stack' do
      r1, r2 = [Class.new(Ramverk::Router), Class.new(Ramverk::Router)]
      app.map r1, r2
      app.routers.must_include [nil, r1]
      app.routers.must_include [nil, r2]
    end

    it 'uses a path if first argument is a string' do
      r1 = Class.new(Ramverk::Router)
      app.map '/admin', r1
      app.routers.must_include ['/admin', r1]
    end
  end

  describe '#use' do
    it 'adds a middleware into the middleware' do
      app.use Rack::Head
      app.middleware.must_include [Rack::Head, [], nil]
    end

    it 'allows arguments' do
      app.use Rack::ETag, 'max-age=0, private, must-revalidate'
      app.middleware.must_include [Rack::ETag, ['max-age=0, private, must-revalidate'], nil]
    end

    it 'allows blocks' do
      block = ->{ }
      app.use Rack::BodyProxy, &block
      app.middleware.must_include [Rack::BodyProxy, [], block]
    end
  end

  describe '.before_load & .after_load' do
    it 'sets config values' do
      app.before_load do |app|
        app.config.default_headers.merge!('Before' => 'called', 'Overidden' => 'before')
        app.config.default_headers.merge!('Overidden' => 'before')
      end

      app.after_load do |app|
        app.config.default_headers.merge!('After' => 'called', 'Overidden' => 'after')
      end

      app.load

      app.config.default_headers['Before'].must_equal 'called'
      app.config.default_headers['After'].must_equal 'called'
      app.config.default_headers['Overidden'].must_equal 'after'
    end
  end

  describe '.load' do
    it 'adds the session middleware if sessions is enabled' do
      app.config.sessions secret: 'changeme'
      app.load
      app.middleware.must_include [Rack::Session::Cookie, [{secret: 'changeme'}], nil]
    end
  end

  describe '#call' do
    it 'raises error if it is enabled' do
      app.config.raise_errors true
      app.map TestApplicationRouter
      app.load
      req = Rack::MockRequest.new(app)
      ->{ req.get('/raise') }.must_raise ArgumentError
    end

    it 'returns 500 if raise_errors is false' do
      app.map TestApplicationRouter
      app.load
      req = Rack::MockRequest.new(app)
      res = req.get('/noraise')
      res.status.must_equal 500
    end

    it 'returns 404 if no route matches the request' do
      app.load
      req = Rack::MockRequest.new(app)
      res = req.get('/noraise')
      res.status.must_equal 404
    end
  end

  it 'parses JSON bodies' do
    app.map BodyParserTestRouter
    app.load
    req = Rack::MockRequest.new(app)
    payload = JSON.generate(username: 'sandelius', password: 'secret')
    res = req.post '/body-parser', 'CONTENT_TYPE' => 'application/json', input: payload
    res.body.must_equal 'sandelius-secret'
  end
end

