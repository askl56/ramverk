require 'test_helper'

describe Ramverk::Route do
  let(:route_class) { Ramverk::Route }

  describe '#initialize' do
    it 'stores the values passed to the constructor' do
      route = route_class.new('POST', '/pages', :index)

      route.methods.must_equal ['POST']
      route.path.must_equal '/pages'
      route.action.must_equal :index
    end
  end

  describe '#compile!' do
    it 'transforms :, () into regexp' do
      route = route_class.new('GET', '/users/:id(/:username)', :show)
      route.compile!(nil)
      ('/users/54/tobias/sandelius' =~ route.pattern).must_equal nil
      ('/users/54/tobias-sandelius' =~ route.pattern).must_equal 0
      ('/users/54/sandelius' =~ route.pattern).must_equal 0
      ('/users/54' =~ route.pattern).must_equal 0
      ('/users' =~ route.pattern).must_equal nil
    end

    it 'transforms * into catch all' do
      route = route_class.new('GET', '*url', :show)
      route.compile!(nil)
      ('/users/54/tobias/sandelius' =~ route.pattern).must_equal 0
      ('/users/54/tobias-sandelius' =~ route.pattern).must_equal 0
      ('/users/54/sandelius' =~ route.pattern).must_equal 0
      ('/users/54' =~ route.pattern).must_equal 0
      ('/users' =~ route.pattern).must_equal 0
    end

    it 'removes multiple and trailing slash' do
      route = route_class.new('GET', 'foo//bar////baz/', :show)
      route.compile!(nil)
      route.path.must_equal('/foo/bar/baz')
    end

    it 'prepends a root if given' do
      route = route_class.new('GET', '/world', :show)
      route.compile!('hello')
      route.path.must_equal('/hello/world')
    end
  end
end
