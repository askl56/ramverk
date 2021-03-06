ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'test'
    add_filter   'test'
  end
end

require 'minitest/autorun'
$:.unshift 'lib'

require 'ramverk'

TEST_ROOT = __dir__
Dir["#{TEST_ROOT}/fixtures/classes/*.rb"].each { |f| require f }

def rack_request(*args)
  ::Rack::Request.new(rack_env(*args))
end

def rack_env(url, method = 'GET', options = {})
  options['REQUEST_METHOD'] = method
  Rack::MockRequest.env_for(url, options)
end

class MiniTest::Spec
  before(:each) { TestApplication.reset }
end
