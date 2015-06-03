require 'test_helper'

describe Ramverk::Configuration do
  let(:config) { Ramverk::Configuration.new }

  describe 'set and get options' do
    it 'sets and gets configuration items' do
      config[:raise_errors].must_equal false
      config[:raise_errors] = true
      config[:raise_errors].must_equal true
    end
  end

  describe '#security' do
    it 'sets and gest security items' do
      config.security[:cross_site_scripting].must_equal true
      config.security[:cross_site_scripting] = false
      config.security[:cross_site_scripting].must_equal false
    end
  end

  describe '#load!' do
    it 'loads up middleware, routers etc' do
      config.load!(TestConfigApplication)
    end
  end
end
