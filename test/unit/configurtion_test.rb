require 'test_helper'

describe Ramverk::Configuration do
  let(:config) { Ramverk::Configuration.new }


  describe '#define_group' do
    it 'can define configuration groups on the fly' do
      config.define_group :assets, prefix: '/assets'
      config.respond_to?(:assets).must_equal true

      new_config = Ramverk::Configuration.new
      new_config.respond_to?(:assets).must_equal false
    end
  end
end
