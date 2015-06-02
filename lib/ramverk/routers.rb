# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require_relative 'router'

module Ramverk
  class Routers
    attr_reader :stack

    # Initialize a new instance of application configurations.
    #
    # @return [Ramverk::Configuration]
    def initialize
      @stack = []
    end

    # Map router(s).
    #
    # @example With no root
    #   map FirstRouter, SecondRouter
    #
    # @example With root
    #   map '/admin', DashboardRouter
    #
    # @param *klasses [Array<Class>] Controller classes to be used.
    #
    # @return [void]
    def map(*routers)
      path = if routers.first.is_a?(::String)
        routers.shift
      end

      routers.each do |router|
        router.routes.each{ |route| route.prepend_path(path) } if path
        @stack << router
      end
    end

    # Compile regular expressions for all defined routes.
    #
    # @api private
    #
    # @return [void]
    def load!
      @stack.each do |router|
        router.routes.each{ |route| route.compile! }
      end
    end

    # Rack compatible endpoint.
    # @api private
    def call(env)
      env['PATH_INFO'].sub!(/(\w)(\/+)\z/, '\1')

      req = ::Rack::Request.new(env)

      @stack.each do |klass|
        match(klass, req) do |route, params|
          req.params.merge!(params) unless params.empty?
          return klass.new(req).process_route(route)
        end
      end

      [404, {}, ['Not Found']]
    end

    # Matches the routes against the given request object.
    #
    # @api private
    #
    # @param env [Hash] Rack's environment hash.
    #
    # @yield [route, params] Matched route and its params.
    # @yieldparam route [Ramverk::Controller::Route] Matched route.
    # @yieldparam params [Hash] Matched parameters.
    #
    # @return [void]
    private def match(klass, req, &block)
      klass.routes.each do |route|
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
