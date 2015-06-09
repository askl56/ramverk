require 'test_helper'
require 'ramverk/view'

class TestViewRouter < Ramverk::Router
  include Ramverk::View
  get '/', :index
  def index
    render 'pages/home', layout: 'app', name: 'TOBIAS'
  end
end

describe Ramverk::View do
  let(:app) { TestApplication }
  let(:router) { TestViewRouter.new(nil, app) }

  before(:each) do
    app.config.view.paths.concat ["#{TEST_ROOT}/fixtures/templates"]
  end

  it 'work in a rack request' do
    app.map TestViewRouter
    app.load

    req = Rack::MockRequest.new(app)
    res = req.get('/')
    res.body.must_equal 'APP HOME TOBIAS'
  end

  describe '#render' do
    it 'renders a layout with a template in yield' do
      catch :finished do
        router.render 'pages/home', layout: 'app', name: 'TOBIAS'
      end

      router.res.body.must_equal 'APP HOME TOBIAS'
    end

    it 'skips the layout if set to false' do
      catch :finished do
        router.render 'pages/home', layout: false, name: 'TOBIAS'
      end

      router.res.body.must_equal 'HOME TOBIAS'
    end

    it 'uses the default layout if non is specified' do
      app.config.view.layout 'default'

      catch :finished do
        router.render 'pages/home', name: 'TOBIAS'
      end

      router.res.body.must_equal 'DEFAULT HOME TOBIAS'
    end

    it 'raises RuntimeError if template not found' do
      ->{ router.render 'unkown' }.must_raise RuntimeError
    end
  end

  describe '#render_to_string' do
    it 'renders the given template as a string' do
      router.render_to_string('pages/home', name: 'KAJSA').must_equal 'HOME KAJSA'
    end
  end

  describe Ramverk::View::Scope do
    let(:scope) { Ramverk::View::Scope.new(router) }

    it 'holds the scope' do
      catch :finished do
        router.render 'scope'
      end
      router.res.body.must_equal 'ESCAPE &lt;p&gt;&lt;&#x2F;p&gt;'
    end

    it 'contains methods to access router and request' do
      scope.router.must_equal router
      scope.req.must_equal router.req
      scope.request.must_equal router.request
    end

    describe '#render' do
      it 'renders a partial' do
        html = scope.render '_partial', name: 'TOBIAS'
        html.must_equal 'PARTIAL TOBIAS'
      end
    end
  end
end
