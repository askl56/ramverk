require 'test_helper'


describe Ramverk do
  describe '.root' do
    it 'returns the application root' do
      Ramverk.root.must_equal File.expand_path('../../', __dir__)
    end
  end

  describe '.env' do
    it 'returns the curren env as a symbol' do
      Ramverk.env.must_equal :test
    end
  end

  describe '.env?' do
    it 'checks if the current env is included' do
      Ramverk.env?(:production, :test).must_equal true
      Ramverk.env?(:development).must_equal false
      Ramverk.env?(:development, :production).must_equal false
    end
  end

  describe '.application' do
    it 'sets the main application and gets it' do
      class TestRamverkApplication < Ramverk::Application ; end
      Ramverk.application.must_equal TestRamverkApplication
      Ramverk.application nil
    end
  end
end
