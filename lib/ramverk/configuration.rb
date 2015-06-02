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
    # @return [void]
    def load!(app)
      # Preload routes regular expressions
      app.routers.load!

      # You should always use protection!
      app.middleware.load!(app)
    end
  end
end
