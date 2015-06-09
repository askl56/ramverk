# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'rack'

require_relative 'configuration'
require_relative 'router'

module Ramverk
  # Ramverk application.
  #
  # @example
  #   require 'ramverk'
  #
  #   class Application < Ramverk::Application
  #   end
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  class Application
    class << self
      # @api private
      # @see http://www.ruby-doc.org/core/Class.html#method-i-inherited
      def inherited(subclass)
        super
        subclass.reset
        Ramverk.application(subclass)
      end

      # Map router(s).
      #
      # @example With no root
      #   map FirstRouter, SecondRouter
      #
      # @example With root
      #   map '/admin', DashboardRouter
      #   map '/users/:user_id', ProfileRouter
      #   map '/users/:user_id/friends', FriendsRouter
      #
      # @param routers [Array<Class>] Router classes or Rack apps to be used.
      #
      # @return [void]
      def map(*klasses)
        path = if klasses.first.is_a?(::String)
          klasses.shift
        end

        klasses.each { |router| routers << [path, router] }
      end

      # Set framework configurations.
      #
      # @example
      #   class Application < Ramverk::Application
      #     config.raise_errors true
      #   end
      #
      # @return [Ramverk::configuration]
      def config
        @config ||= Configuration.new
      end

      # Environment based configurations.
      #
      # @example
      #   configure :development, :test do |app|
      #     app.config.raise_errors true
      #   end
      #
      # @param environments [Array<Symbol>] Environments to set config in.
      #
      # @yield [app] Application class context.
      # @yieldparam [Ramverk::Application] app Current application.
      #
      # @return [void]
      def configure(*environments, &block)
        yield(self) if ::Ramverk.env?(*environments)
      end

      # Adds(appends) a middleware to the stack.
      #
      # @example
      #   use Rack::ETag, 'max-age=0, private, must-revalidate'
      #
      # @param middleware [Class] Middleware class.
      # @param args [Array<*>] Middleware arguments (splat).
      # @param block [Proc] Middleware block (optional).
      #
      # @return [void]
      def use(klass, *args, &block)
        middleware << [klass, args, block]
      end

      # Hooks to be called before the application has loaded.
      #
      # @example
      #   class App < Ramverk::Application
      #     before_load do |app|
      #       initialize_stuff
      #     end
      #   end
      #
      # @yield [app] Application class context.
      # @yieldparam [Ramverk::Application] app Current application.
      #
      # @return [void]
      def before_load(&block)
        onload[:before] << block
      end

      # Hooks to be called after the application has loaded.
      #
      # @example
      #   class App < Ramverk::Application
      #     after_load do |app|
      #       finalize_stuff
      #     end
      #   end
      #
      # @yield [app] Application class context.
      # @yieldparam [Ramverk::Application] app Current application.
      #
      # @return [void]
      def after_load(&block)
        onload[:after] << block
      end

      # @api private
      def reset
        @config = nil
        @onload = nil
        @middleware = nil
        @routers = nil
        @builder = nil
        @app = nil
      end

      # @api private
      def middleware
        @middleware ||= []
      end

      # @api private
      def routers
        @routers ||= []
      end

      # @api private
      def builder
        @builder ||= ::Rack::Builder.new
      end

      # @api private
      def onload
        @onload ||= { before: [], after: [] }
      end

      # Boots up the application.
      #
      # @return [Rack::Builder]
      def load
        @app ||= begin
          onload[:before].each { |block| block.call(self) }

          setup_session_middleware

          middleware.each { |m, args, block| builder.use m, *args, &block }

          routers.each do |root, router|
            router.routes.each{ |route| route.compile(root) }
          end

          builder.run self.new

          onload[:after].each { |block| block.call(self) }

          builder
        end
      end

      # Rack compatible endpoint.
      # @api private
      def call(env)
        @app.call(env)
      rescue ::Exception => e
        raise e if config.raise_errors
        [500, {}, ['[500] Internal Server Error']]
      end

      # @api private
      private def setup_session_middleware
        if sessions = config.sessions
          opts = sessions.is_a?(::Hash) ? sessions : {}
          use ::Rack::Session::Cookie, opts
        end
      end
    end

    # @see config
    def config
      self.class.config
    end

    # Rack compatible endpoint.
    # @api private
    def call(env)
      # Remove trailing slashes in the URL.
      env['PATH_INFO'].sub!(/(\w)(\/+)\z/, '\1')

      self.class.routers.each do |root, router|
        router.match(env) do |route, params|
          req = ::Rack::Request.new(env)
          req.params.merge!(params) unless params.empty?
          return router.new(req, self).process_route(route)
        end
      end

      [404, {}, ['[404] Not Found']]
    end
  end
end
