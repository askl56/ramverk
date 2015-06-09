# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'tilt'
require 'tilt/erb'

module Ramverk
  class Configuration
    def view
      @view ||= ViewConfiguration.new
    end
  end

  class ViewConfiguration
    # Initialize default view configuations.
    #
    # @return [Ramverk::ViewConfig]
    def initialize
      @engine = :erb
      @paths = []
      @layout = nil
      @layouts_dir = 'layouts'
      @cache = ::Tilt::Cache.new
      @reload_templates = false
    end

    # Template rendering engine to be used (defaults to erb).
    #
    # @example Change engine ti slim
    #   require 'slim'
    #
    #   config.view.engine :slim
    #
    # @param new_engine [Symbol] Name of the engine to be used.
    #
    # @return [Symbol]
    def engine(new_engine = nil)
      @engine = new_engine if new_engine
      @engine
    end

    # Paths to where view templates is located.
    #
    # @example
    #   config.view.paths += ["#{Ramverk.root}/views"]
    #
    # @return [Array]
    def paths
      @paths
    end

    # Name of the default layout to be used (layouts are disabled by default).
    #
    # @example
    #   config.view.layout 'application'
    #
    # @return [String, NilClass]
    def layout(new_layout = nil)
      @layout = new_layout if new_layout
      @layout
    end

    # Directory name for layouts. The name is appended to the paths.
    #
    # @param dir [String] Directory name.
    #
    # @return [String]
    def layouts_dir(dir = nil)
      @layouts_dir = dir if dir
      @layouts_dir
    end

    # Template cache. The cache object must implemenet `fetch(key, &block)` in
    # order to work. By deault `Tilt::Cache` is being used and it store
    # compiled templates in memory.
    #
    # @param new_cache [Object] Cache object.
    #
    # @return [Object]
    def cache(new_cache = nil)
      @cache = new_cache if new_cache
      @cache
    end

    # Reload all templates upon each request. This is disabled by default and
    # not recommended in production environments.
    #
    # @example Enable reload
    #   config.view.reload_templates true
    #
    # @param reload [boolean, nil] True for reload and false for not.
    #
    # @return [boolean]
    def reload_templates(reload = nil)
      @reload_templates = reload unless reload == nil
      @reload_templates
    end
  end

  # Module that enables view rendering from routers.
  #
  # @example
  #   class PostsRouter < Ramverk::Router
  #     include Ramverk::View
  #
  #     get '/', :index
  #     def index
  #       render 'posts/index'
  #     end
  #   end
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  module View
    # @api private
    # @see http://www.ruby-doc.org/core/Module.html#method-i-included
    def self.included(base)
      base.before :_view_reload_templates
    end

    # @api private
    private def _view_reload_templates
      app.config.view.cache.clear if app.config.view.reload_templates
    end

    # Render a template, and layout if enabled, and write the response. This
    # method automatically sets the content type to `:html`.
    #
    # Rendering options:
    #   - layout: String, false
    #
    # @example
    #   def index
    #     render 'posts/index'
    #   end
    #
    # @example With locals
    #   def index
    #     posts = [{title: 'One'}, {title: 'two'}]
    #     render 'posts/index', posts: posts
    #   end
    #
    # @example With different layout
    #   def index
    #     render 'sessions/new', layout: 'auth'
    #   end
    #
    # Rest of the keys in `options` is available as locals inside the template.
    #
    # @param template [String] Name of the partial to render.
    # @param options [Hash] Render options and locals.
    #
    # @return [void]
    def render(template, options = {})
      view = app.config.view

      res.content_type(:html)

      layout = options.delete(:layout)
      layout = view.layout if layout.nil?

      content = render_to_string(template, options)

      res.write(content) unless layout

      filename = "#{view.layouts_dir}/#{layout}"
      layout_tpl = lookup_template(filename)

      res.write(read_template(layout_tpl, options) { content })
    end

    # Render a partial within a view.
    #
    # @example
    #   html = render_to_string('posts/index')
    #
    # @param template [String] Name of the template to render.
    # @param locals [Hash] Locals for the template.
    #
    # @return [String] Rendered content.
    def render_to_string(template, locals = {})
      read_template(lookup_template(template), locals)
    end

    # @api private
    private def read_template(template, locals = {}, &block)
      template.render(view_scope, locals, &block)
    end

    # @api private
    private def view_scope
      @_view_scope ||= Scope.new(self)
    end

    # @api private
    private def lookup_template(template)
      view = app.config.view
      filename = "#{template}.#{view.engine}"

      view.cache.fetch(filename) do
        tpl = view.paths.each do |path|
          fullpath = "#{path}/#{filename}"
          break ::Tilt.new(fullpath) if ::File.exist?(fullpath)
        end

        raise "Missing template: #{filename}" if tpl.is_a?(::Array)
        tpl
      end
    end

    class Scope
      attr_reader :router

      # Initializes the view scope.
      #
      # @param router [Ramverk::Router] Router context.
      #
      # @return [Ramverk::View::Scope]
      def initialize(router)
        @router = router
      end

      # Incoming request object.
      #
      # @return [Rack::Request]
      def request
        @router.request
      end
      alias_method :req, :request

      # Partial renderer.
      #
      # @example
      #   <%= render 'posts/_meta', meta: post.meta_data %>
      #
      # @param template [String] Name of the partial to render.
      # @param locals [Hash] Locals for the partial.
      #
      # @return [String] Rendered partial.
      def render(template, locals = {})
        @router.render_to_string(template, locals)
      end

      # Escape ampersands, brackets and quotes to their HTML/XML entities.
      #
      # @see http://www.rubydoc.info/github/rack/rack/Rack/Utils#escape_html-class_method
      #
      # @example
      #   <%=e '<p>hello</p>' %>
      #
      # @param text [String] Text to be escaped.
      #
      # @return [Strng]
      def h(text)
        ::Rack::Utils.escape_html(text)
      end
    end
  end
end
