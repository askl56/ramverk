# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'class_attribute'

require_relative 'route'
require_relative 'callbacks'
require_relative 'response'

module Ramverk
  class Router
    include ::ClassAttribute

    # @api private
    class_attribute :routes, :error_handlers, :callbacks

    # @api private
    self.routes = []
    self.error_handlers = {}
    self.callbacks = Callbacks.new

    # Add an error handler for an exception that may be raised.
    #
    # @example
    #   error ActiveRecord::RecordNorFound, :error_404
    #
    #   def error_404
    #     res.head 404
    #   end
    #
    # @param exceptions [Array<Class>] Exception classes to rescue.
    # @param method [Symbol] Controller method to be called.
    #
    # @return [void]
    def self.error(*exceptions, method)
      exceptions.each{ |err| self.error_handlers[err] = method }
    end

    # Adds a before filter that's run before the requested action.
    #
    # @example
    #   before :authenticate, except: :login
    #
    #   def authenticate
    #     res.status(401).write('Unauthorized!')
    #   end
    #
    # @param callbacks [Array<Symbol>] Callbacks to be called before the
    #   action.
    # @param except [Symbol, Array<Symbol>] Callbacks should be run on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be run on the
    #   provided action(s).
    #
    # @return [void]
    def self.before(*callbacks, except: nil, only: nil)
      self.callbacks.add(*callbacks, except: except, only: only)
    end

    # Skips an already defined callback. Mostly created inside a parent
    # router.
    #
    # @example
    #   skip_before :authenticate, only: :show
    #
    #   def show
    #     # authenticate is not run before this action
    #   end
    #
    # @param callbacks [Array<Symbol>] Callbacks to be skipped.
    # @param except [Symbol, Array<Symbol>] Callbacks should be skipped on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be skipped on
    #  the provided action(s).
    #
    # @return [void]
    def self.skip_before(*callbacks, except: nil, only: nil)
      self.callbacks.skip(*callbacks, except: except, only: only)
    end

    # Adds a new route to the routers collection.
    #
    # @raise [NameError] If the action name is reserved.
    #
    # @param method [String, Array<String>] Request method to be matched.
    # @param path [String, Regexp] URL path to match.
    # @param action [Symbol] Name of the action/method to call.
    # @param options [Hash] Route options.
    #
    # @return [void]
    def self.route(method, path, action, options = {})
      if self.reserved_action_names.include?(action)
        raise ::NameError, "Action name `#{action}` is reserved"
      end

      self.routes << Route.new(method, path, action, options)
    end

    # @see {Ramverk::Router.route}
    def self.get(*args) ; route('GET', *args) end
    # @see {Ramverk::Router.route}
    def self.post(*args) ; route('POST', *args) end
    # @see {Ramverk::Router.route}
    def self.put(*args) ; route('PUT', *args) end
    # @see {Ramverk::Router.route}
    def self.patch(*args) ; route('PATCH', *args) end
    # @see {Ramverk::Router.route}
    def self.delete(*args) ; route('DELETE', *args) end
    # @see {Ramverk::Router.route}
    def self.options(*args) ; route('OPTIONS', *args) end
    # @see {Ramverk::Router.route}
    def self.link(*args) ; route('LINK', *args) end
    # @see {Ramverk::Router.route}
    def self.unlink(*args) ; route('UNLINK', *args) end

    # Returns a list with resereved action names.
    #
    # @return [Array<Symbol>] The list.
    def self.reserved_action_names
      [:request, :req, :response, :res, :params, :route, :process_route,
       :process_action]
    end

    # @api private
    ENV_REQUEST_METHOD = 'REQUEST_METHOD'.freeze
    ENV_REQUEST_PATH = 'PATH_INFO'.freeze
    def self.match(env, &block)
      self.routes.each do |route|
        next unless route.methods.include?(env[ENV_REQUEST_METHOD])

        if result = env[ENV_REQUEST_PATH].match(route.pattern)
          unless result.names.empty?
            params = ::Hash[Array(result.names).zip(result.captures)]
          end

          return yield(route, params || {})
        end
      end
    end

    # Object initializer.
    #
    # @param req [Rack::Request] Incoming request object.
    # @param app [Ramverk::Application] Current application.
    #
    # @return [Ramverk::Router]
    def initialize(req, app)
      @_request = req
      @_route = nil
      @_app = app
    end

    # Current application.
    #
    # @return [Ramverk::Application, nil]
    def app
      @_app
    end

    # Incoming request object.
    #
    # @return [Rack::Request]
    def request
      @_request
    end
    alias_method :req, :request

    # Outgoing response object.
    #
    # @return [Ramverk::Response]
    def response
      @_response ||= Response.new(@_app)
    end
    alias_method :res, :response

    # The matched route object.
    #
    # @return [Ramverk::Route]
    def route
      @_route
    end

    # Returns the params hash. Short hand for `_request.params`.
    #
    # @return [Hash]
    def params
      @_params ||= symbolize_keys!(@_request.params)
    end

    # Process and dispatch the given route.
    #
    # @raise [Ramverk::Router::NoActionError] If action is not defined.
    # @raise [RuntimeError] If no response has been sent.
    #
    # @param route [Ramverk::Route] Route to be processed.
    #
    # @api private
    #
    # @return [Array] Rack endpoint.
    def process_route(route)
      action = route.action
      router = self.class

      unless router.public_method_defined?(action)
        raise NoActionError, "Missing action '#{action}' in #{router.name}"
      end

      @_route = route

      result = catch :finished do
        begin
          process_action(action)
        rescue ::Exception => kaboom
          if meth = router.error_handlers[kaboom.class]
            send(meth, kaboom)
          else
            raise kaboom
          end
        end
      end

      raise 'Missing response' unless result.is_a?(::Array)

      result
    end

    # Calls the given action. If a different behavior is required this is the
    # method to override in a subclass/module.
    #
    # @note When this method is run it's already validated that the action
    #   exists in the router and is ready to be called.
    #
    # @param action [Symbol] Name of the action to process.
    #
    # @return [void]
    private def process_action(action)
      self.class.callbacks.run(self, action)
      send(action)
    end

    # @api private
    private def symbolize_keys!(hash)
      hash.keys.each do |k|
        v = hash.delete(k)
        symbolize_keys!(v) if v.is_a?(::Hash)
        hash[k.to_sym] = v
      end
      hash
    end

    # Error raised when the requested action method is not found.
    class NoActionError < ::NoMethodError ; end
  end
end
