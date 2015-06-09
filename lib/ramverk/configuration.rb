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
      @body_parsers = {
        'application/json' => ->(body) { ::JSON.parse(body) }
      }
      @default_headers = {
        'Content-Type' => 'text/plain',
        'X-Frame-Options' => 'SAMEORIGIN',
        'X-XSS-Protection' => '1; mode=block',
        'X-Content-Type-Options' => 'nosniff'
      }
    end

    # Body parsers. By default the framework only parses normal and JSON
    # bodies. Here you can change what to parse.
    #
    # @example Clear all parsers and only parse normal body:
    #   config.body_parsers.clear
    #
    # @example Change the JSON parser to use `Oj` instead:
    #   config.body_parsers['application/json'] = ->(body) { Oj.load(body) }
    #   # or
    #   config.body_parsers.merge!(
    #     'application/json' => ->(body) { Oj.load(body) }
    #   )
    #
    # @return [Hash]
    def body_parsers
      @body_parsers
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
  end
end
