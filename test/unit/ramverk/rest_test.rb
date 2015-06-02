require 'test_helper'

class TestRESTRouter < Ramverk::Router
end

describe Ramverk::Router do
  describe 'REST methods' do
    %w(GET POST PUT PATCH DELETE OPTIONS LINK UNLINK).each do |method|
      describe ".#{method.downcase}" do
        it "creates a #{method} route" do
          TestRESTRouter.send(method.downcase, '/', :index)
          TestRESTRouter.routes.last.methods.must_equal [method]
        end
      end
    end
  end
end
