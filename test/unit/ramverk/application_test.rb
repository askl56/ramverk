require 'test_helper'

describe Ramverk::Application do
  describe '.use' do
    it 'is a short-hand for middleware.use' do
      TestApplication.use Rack::Head
      TestApplication.builder.middleware.must_include [Rack::Head, [], nil]
    end
  end

  describe '.configure' do
    it 'does not set configuration if environment does not match' do
      TestApplication.config[:raise_errors] = true
      TestApplication.configure :production do
        config[:raise_errors] = false
      end
      TestApplication.config[:raise_errors].must_equal true
      TestApplication.configure :development, :test do
        config[:raise_errors] = false
      end
      TestApplication.config[:raise_errors].must_equal false
    end
  end

  describe '.map' do
    it 'adds routers to the stack' do
      TestApplication.builder.routers.must_include [nil, TestApplicationRouter]
    end
  end

  describe '#call' do
    it 'raises errors if raise_errors is true' do
      TestApplication.config[:raise_errors] = true
      ->{ TestApplication.new.call(rack_env('http://lolcahost:9292/hello')) }.must_raise ArgumentError
    end

    it 'does not raises errors if raise_errors is false (default)' do
      TestApplication.config[:raise_errors] = false
      res = TestApplication.new.call(rack_env('http://lolcahost:9292/hello'))
      res[0].must_equal 500
    end
  end

  describe '.before_load & .after_load' do
    it 'sets config values' do
      TestOnLoadApplication.config[:first_name] = nil
      TestOnLoadApplication.config[:last_name] = nil
      TestOnLoadApplication.load!
      TestOnLoadApplication.config[:first_name].must_equal 'Tobias'
      TestOnLoadApplication.config[:last_name].must_equal 'Sandelius'
    end
  end
end
