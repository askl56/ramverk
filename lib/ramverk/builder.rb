# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'rack/protection'

require_relative 'router'

module Ramverk
  class Builder
    attr_reader :middleware, :routers

    # Initialize a new instance of application configurations.
    #
    # @return [Ramverk::Builder]
    def initialize
      @middleware = []
      @routers = []
      @racks = []
    end

    # Adds(appends) a middleware to the stack.
    #
    # @see http://www.rubydoc.info/github/rack/rack/Rack/Builder#use-instance_method
    def use(middleware, *args, &block)
      @middleware << [middleware, args, block]
    end

    # Map router(s).
    #
    # @note If a Rack app is mapped, that path path it WILL HAVE precedence
    # over mappeped routers. Only mapp rack apps with url prefix you're not
    # using with your routers.
    #
    # @example The Rack app (second one) will weight more that the router.
    #   map '/assets', AssetsRouter
    #   map '/assets', Sprockets::Environment.new.environment
    #
    # @example With no root
    #   map FirstRouter, SecondRouter
    #
    # @example With root
    #   map '/admin', DashboardRouter
    #
    # @param *routers [Array<Class>] Router classes or Rack apps to be used.
    #
    # @return [void]
    def map(*routers)
      path = if routers.first.is_a?(::String)
        routers.shift
      end

      routers.each do |app|
        meta = [path, app]
        if app < Router
          @routers << meta
        else
          @racks << meta
        end
      end
    end

    # Loads up the builder stack (middleware, routers and rack apps).
    #
    # @api private
    #
    # @return [Ramverk::Middleware]
    def load!(app)
      routers  = @routers
      @builder = ::Rack::Builder.new

      load_session_stack(app)
      load_security_stack(app)

      @middleware.each { |m, args, block| @builder.use m, *args, &block }

      routers.each do |root, router|
        router.routes.each{ |route| route.compile!(root) }
      end

      @racks.each do |root, app|
        @builder.map(root) { run app }
      end

      @builder.map('/') { run ::Ramverk::Endpoint.new(routers) }
    end

    # Rack compatible endpoint.
    # @api private
    def call(env)
      @builder.call(env)
    end

    # @api private
    private def load_session_stack(app)
      if enabled = app.config[:session]
        opts = enabled.is_a?(::Hash) ? enabled : {}
        use ::Rack::Session::Cookie, opts
      end
    end

    # @api private
    private def load_security_stack(app)
      if app.config.security[:cross_site_scripting]
        use ::Rack::Protection::EscapedParams
        use ::Rack::Protection::XSSHeader
      end

      if frame = app.config.security[:clickjacking]
        use ::Rack::Protection::FrameOptions, frame_options: frame
      end

      if app.config.security[:directory_traversal]
        use ::Rack::Protection::PathTraversal
      end

      if app.config.security[:session_hijacking]
        raise 'Session must be enabled in order to use Session Hijacking
               protection' unless app.config[:session]
        use ::Rack::Protection::SessionHijacking
      end

      if app.config.security[:ip_spoofing]
        use Rack::Protection::IPSpoofing
      end
    end
  end

  class Endpoint
    # @api private
    # @param [Array<[String|nil, Ramverk::Router]>] Routers to match.
    def initialize(routers)
      @routers = routers
    end

    # Rack compatible endpoint.
    # @api private
    def call(env)
      env['PATH_INFO'].sub!(/(\w)(\/+)\z/, '\1')

      req = ::Rack::Request.new(env)

      @routers.each do |root, router|
        match(router, req) do |route, params|
          req.params.merge!(params) unless params.empty?
          return router.new(req).process_route(route)
        end
      end

      [404, {}, ['Not Found']]
    end

    # @api private
    private def match(router, req, &block)
      router.routes.each do |route|
        next unless route.methods.include?(req.request_method)

        if result = req.path.match(route.pattern)
          unless result.names.empty?
            params = ::Hash[Array(result.names).zip(result.captures)]
          end

          return yield(route, params || {})
        end
      end
    end
  end
end
