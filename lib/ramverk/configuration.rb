# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

autoload :JSON, 'json'

module Ramverk
  # Framework configurations.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  class Configuration
    # Initializes and sets default configuration values.
    #
    # @return [Ramverk::Configuration]
    def initialize
      @raise_errors = false
      @sessions = false
      @json_renderer = ->(data) { ::JSON.generate(data) }
      @default_headers = {
        'Content-Type' => 'text/plain',
        'X-Frame-Options' => 'SAMEORIGIN',
        'X-XSS-Protection' => '1; mode=block',
        'X-Content-Type-Options' => 'nosniff'
      }
    end

    # Default headers that is sent to the client.
    #
    # @example
    #   config.default_headers.merge!(
    #     'Header-Name' => 'Header-Value'
    #   )
    #
    # @return [Hash]
    def default_headers
      @default_headers
    end

    # Raise errors within the application (disabled by default).
    #
    # @example Enable errors
    #   config.raise_errors true
    #
    # @param raise_them [boolean, nil] Should we raise errors?
    #
    # @return [boolean]
    def raise_errors(raise_them = nil)
      @raise_errors = raise_them unless raise_them == nil
      @raise_errors
    end

    # Session handling (disabled by default).
    #
    # @example Enable sessions
    #   config.sessions secret: 'changeme'
    #
    # @param config [Hash, nil] Session configurations.
    #
    # @return [FalseClass, Hash]
    def sessions(config = nil)
      @sessions = config if config
      @sessions
    end

    # Renderer used when generating JSOn from data.
    #
    # @example Change render method
    #   config.json_renderer ->(data) { Oj.dump(data, mode: :compat) }
    #
    # @param renderer [Proc] Json renderer block.
    #
    # @return [Proc]
    def json_renderer(renderer = nil)
      @json_renderer = renderer if renderer
      @json_renderer
    end

    # Define a new configuration group with defaults.
    #
    # @example
    #   class AssetsConfig
    #     def initialize
    #       @debug = false
    #     end
    #
    #     def debug(enable = nil)
    #       @debug = enable unless enable == nil
    #       @debug
    #     end
    #   end
    #
    #   config.define_group(:assets, AssetsConfig.new)
    #   config.assets.debug true
    #
    # @param name [Symbol] Name of the group.
    # @param value [*] Config value.
    #
    # @return [void]
    def define_group(name, value)
      define_singleton_method(name) { instance_variable_get "@#{name}" }
      instance_variable_set "@#{name}", value
    end
  end
end
