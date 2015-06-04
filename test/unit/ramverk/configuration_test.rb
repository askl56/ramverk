require 'test_helper'

describe Ramverk::Configuration do
  let(:config) { Ramverk::Configuration.new }

  it 'returns false if already loaded' do
    class TestUnloadedConfigApplication < Ramverk::Application ; end
    config.load!(TestUnloadedConfigApplication).must_equal true
    config.load!(TestUnloadedConfigApplication).must_equal false
    ::Object.send(:remove_const, :TestUnloadedConfigApplication)
  end

  describe 'set and get options' do
    it 'sets and gets configuration items' do
      config[:raise_errors].must_equal false
      config[:raise_errors] = true
      config[:raise_errors].must_equal true
    end
  end

  describe '#define_group' do
    it 'can define configuration groups on the fly' do
      config.define_group :assets, prefix: '/assets'
      config.assets[:prefix].must_equal '/assets'
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
