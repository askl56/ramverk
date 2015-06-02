# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'rack/protection'

module Ramverk
  # Rack middleware stack for the application.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  #
  # @attr_reader stack [Array] Current stack.
  class Middleware
    attr_reader :stack

    # Initialize a new instance of application configurations.
    #
    # @return [Ramverk::Configuration]
    def initialize
      @stack = []
    end

    # Adds(appends) a middleware to the stack.
    #
    # @see http://www.rubydoc.info/github/rack/rack/Rack/Builder#use-instance_method
    def use(middleware, *args, &block)
      @stack << [middleware, args, block]
    end

    # Rack compatible endpoint.
    # @api private
    # :nocov:
    def call(env)
      @builder.call(env)
    end
    # :nocov:

    # Loads up the middleware stack.
    #
    # @api private
    #
    # @return [Ramverk::Middleware]
    def load!(app)
      @builder = ::Rack::Builder.new

      load_session_stack(app)
      load_security_stack(app)

      @stack.each { |m, args, block| @builder.use m, *args, &block }
      @builder.run app.routers
    end

    # @api private
    private def load_session_stack(app)
      if enabled = app.config[:session]
        opts = enabled.is_a?(::Hash) ? enabled : {}
        @session_loaded = true
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
               protection' unless @session_loaded

        use ::Rack::Protection::SessionHijacking
      end

      if app.config.security[:ip_spoofing]
        use Rack::Protection::IPSpoofing
      end
    end
  end
end
