# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
  # Framework configurations.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  #
  # @attr_reader security [Struct] Security options.
  class Configuration
    attr_reader :security

    # Object initializer.
    def initialize
      @options = {
        raise_errors: false,
        session: false
      }

      @security = {
        cross_site_scripting: true,
        clickjacking: 'SAMEORIGIN',
        directory_traversal: true,
        session_hijacking: false,
        ip_spoofing: true
      }

      @loaded = false
    end

    # Define a new configuration group with defaults.
    #
    # @example
    #   config.define_group :assets, prefix: '/assets'
    #   config.assets[:prefix] # => '/assets'
    #
    # @param name [Symbol] Name of the group.
    # @param defaults [Hash] Group default options.
    #
    # @return [void]
    def define_group(name, defaults = {})
      singleton_class.class_eval do; attr_reader name; end
      instance_variable_set "@#{name}", defaults
    end

    # Gets an existing configuration value.
    #
    # @example
    #   config[:raise_errors] # => false
    #
    # @param key [Symbol] Item key.
    #
    # @return [*]
    def [](key)
      @options[key]
    end

    # Sets a configuration value.
    #
    # @example
    #   config[:raise_errors] = true
    #
    # @param key [Symbol] Item key.
    # @param value [*] Item value.
    #
    # @return [void]
    def []=(key, value)
      @options[key] = value
    end

    # Loads the framework and application.
    #
    # @api private
    #
    # @param app [Ramverk::Application] Ramverk application.
    #
    # @return [boolean]
    def load!(app)
      return false if @loaded
      @loaded = true

      app.on_load[:before].each { |block| block.call(app) }

      # Setup all middleware, Routers and rack endpoints.
      app.builder.load!(app)

      app.on_load[:after].each { |block| block.call(app) }

      true
    end
  end
end
