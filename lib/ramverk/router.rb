# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require_relative 'response'

module Ramverk
  class Router
    include ::ClassAttribute

    # @api private
    class_attribute :routes, :error_handlers

    # @api private
    self.routes = []

    # @api private
    self.error_handlers = {}

    # Add an error handler for an exception that may be raised.
    #
    # @example
    #   error ActiveRecord::RecordNorFound, :error_404
    #
    #   def error_404
    #     head 404
    #   end
    #
    # @param *exceptions [Array<Class>] Exception classes to rescue.
    # @param method [Symbol] Controller method to be called.
    #
    # @return [void]
    def self.error(*exceptions, method)
      exceptions.each{ |e| self.error_handlers[e] = method }
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
      if reserved_action_names.include?(action)
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

    # Object initializer.
    #
    # @param req [Rack::Request] Incoming request object.
    def initialize(req)
      @_request  = req
      @_response = Response.new(Response::CONTENT_TYPE => 'text/plain')
      @_route    = nil
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
      @_response
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
      @_request.params
    end

    # Process and dispatch the given route.
    #
    # @raise [Ramverk::Router::NoActionError] If action is not defined.
    # @raise [RuntimeError] If no response has been sent.
    #
    # @param route [Ramverk::Router::Route] Route to be processed.
    # @param req [Rack::Request] Request object to match.
    #
    # @api private
    #
    # @return [Array] Rack endpoint.
    def process_route(route)
      action = route.action

      unless self.class.public_method_defined?(action)
        raise NoActionError, "Missing action '#{action}' in #{self.class.name}"
      end

      @_route = route

      result = catch :finished do
        begin
          process_action(action)
        rescue ::Exception => kaboom
          if meth = self.class.error_handlers[kaboom.class]
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
    # @note When this method is run it's already validated that the action do
    #   exist in the router and is ready to be called.
    #
    # @param action [Symbol] Name of the action to process.
    #
    # @return [void]
    private def process_action(action)
      send(action)
    end

    # Error raised when the requested action method is not found.
    class NoActionError < ::NoMethodError ; end
  end

  # The Route class represents a single route.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  #
  # @attr_reader methods [Array] Request methods to be matched.
  # @attr_reader path [String] URL path.
  # @attr_reader action [Symbol] Name of the action this route is going to call.
  # @attr_reader options [Hash] Route options.
  # @attr_reader pattern [Regexp] Matchable regular expression. Created after compilation.
  class Route
    # @private
    DEFAULT_STARTING = '\A'.freeze
    # @private
    DEFAULT_ENDING = '\z'.freeze

    # @api private
    COLON_REGEXP = /(^?):([\w]+)/.freeze
    # @api private
    COLON_REPLACE_REGEXP = '[\w\-]+'.freeze

    # @api private
    STAR_REGEXP = /(^?)\*([\w]+)/.freeze
    # @api private
    STAR_REPLACE_REGEXP = '(?<\2>.*)'.freeze

    # @api private
    OPTIONAL_REGEXP = /\((.*)\)/.freeze
    # @api private
    OPTIONAL_REPLACE_REGEXP = '(?:\1)?'.freeze

    # @private
    PATH_SEPARATOR = '/'.freeze

    # @private
    TRIM_REGEXP = /\A[\/]+|[\/]+\z/.freeze

    attr_reader :methods, :path, :action, :options, :pattern

    # Object initializer.
    #
    # @param methods [String, Array<String>] Request method(s) to be matched.
    # @param path [String, Regexp] URL path.
    # @param action [Symbol] Name of the action this route is going to call.
    # @param options [Hash] Route options.
    def initialize(methods, path, action, options = {})
      @methods = Array(methods)
      @path    = path
      @action  = action
      @options = options
    end

    # Prepends the current path with the given one.
    #
    # @param path [String] path to be prepended.
    #
    # @return [void]
    def prepend_path(path)
      @path.insert 0, path + PATH_SEPARATOR
    end

    # Compiles the path into a matchable regular expression.
    #
    # @api private
    #
    # @return [Regexp]
    def compile!
      @path = sanitize_path(@path)
      @pattern = path_to_regexp(@path)
    end

    # @api private
    private def sanitize_path(path)
      path.gsub!(/[\/]{2,}/, PATH_SEPARATOR)
      path.gsub!(TRIM_REGEXP, '')
      path.insert(0, PATH_SEPARATOR)
      path
    end

    # @api private
    private def path_to_regexp(path)
      pattern = path.dup
      pattern.gsub!(OPTIONAL_REGEXP, OPTIONAL_REPLACE_REGEXP)
      pattern.gsub!(STAR_REGEXP, STAR_REPLACE_REGEXP)
      pattern.gsub!(COLON_REGEXP, "(?<\\2>#{COLON_REPLACE_REGEXP})")
      ::Regexp.new(DEFAULT_STARTING + pattern + DEFAULT_ENDING)
    end
  end
end
