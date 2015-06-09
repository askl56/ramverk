# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
  # Response represents an HTTP res.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  class Response
    # @api private
    CONTENT_TYPE = 'Content-Type'.freeze

    # @api private
    CONTENT_LENGTH = 'Content-Length'.freeze

    # Object intializer. Sets up default values.
    #
    # @param app [Ramverk::Application] Main application.
    #
    # @return [Ramverk::Response]
    def initialize(app)
      @app = app
      @status = 200
      @json_renderer = app.config.json_renderer
      @header = app.config.default_headers.dup
      @body = []
    end

    # Setter and getter for content type.
    #
    # @example Setter
    #   res.content_type(:json)
    #
    #   res.type(:json) # alias method
    #
    # @example Getter
    #   type = res.content_type
    #   type # => 'application/json'
    #
    #   res.type # alias method
    #
    # @param new_type [Symbol] New content type.
    #
    # @return [String, Ramverk::Response]
    def content_type(new_type = nil)
      return @content_type unless new_type

      @content_type = if new_type.is_a?(::String)
        new_type
      else
        ::Rack::Mime::MIME_TYPES[".#{new_type}"]
      end

      self
    end
    alias_method :type, :content_type

    # Setter and getter for response header.
    #
    # @example Get existing header
    #   type = res.header('Content-Type')
    #
    # @example Set single header
    #   res.header('Content-Type', 'application/json')
    #
    # @example Set multiple headers
    #   res.header('Content-Type' => 'application/json')
    #
    # @example Set header using the hash
    #   res.header['Content-Type'] = 'text/xml'
    #
    # @param header [String, Hash] String for getitng or single setting, else hash.
    # @param value [String, nil] String for single setting or nil for mass or getting.
    #
    # @return [String, self]
    def header(header = nil, value = nil)
      return @header[header] if header.is_a?(::String) && !value
      return @header unless header

      if value
        @header[header] = value
      else
        @header.merge!(header)
      end

      self
    end

    # Setter and getter for response body.
    #
    # @example Setter
    #   res.body('Hello World')
    #
    # @example Getter
    #   body = res.body
    #
    # @param body [*, nil] Body for setter or nil for getter.
    #
    # @return [*, self] [description]
    def body(body = nil)
      return @body.join unless body
      @body = [body]
      self
    end

    # Setter and getter for status code.
    #
    # @example Setter
    #   res.status(404)
    #
    # @example Getter
    #   status = res.status
    #
    # @param code [Integer, nil] Status code when setting or nil when getting.
    #
    # @return [Integer, self]
    def status(code = nil)
      return @status unless code
      @status = code
      self
    end

    # Writes and finishes the res.
    #
    # @note Breaks code execution and return the res.
    #
    # @param body [String] Optional body.
    #
    # @return [void]
    def write(body = nil)
      self.body(body) if body
      throw :finished, finish
    end

    # Sends a "blank" response body with only status and headers.
    #
    # @note Breaks code execution and return the res.
    #
    # @param status [Integer] Response status to be sent.
    #
    # @return [void]
    def head(status)
      @status = status
      @body = []
      throw :finished, finish
    end

    # Creates a `Location` header and redirects the user. If the current
    # status does not start with a `3` a new, `302`, status is set.
    #
    # @note Breaks code execution and return the res.
    #
    # @param url [String] Destination.
    #
    # @return void
    def redirect(url)
      @status = 302 unless @status[0] == 3
      @header['Location'] = url
      throw :finished, finish
    end

    # Response json output. If the `data` s a string then it will assume that
    # the data already is json and no generation is done.
    #
    # If `data` respond to `as_json` it will be called. If the data responds to
    # `map!` it will be mapped and `as_json` is called  if the object responds
    # to it.
    #
    # This method also sets the json content type and a new response status
    # code if `status` is given in the `options`.
    #
    # @note Breaks code execution and return the res.
    #
    # @example
    #   res.json('{"hello":"world"}') # => '{"hello":"world"}'
    #   res.json(hello: 'world')      # => '{"hello":"world"}'
    #   res.json([{hello: 'world'}])  # => '[{"hello":"world"}]'
    #
    # @param data [String, Object, Enumerable] Data to be generated.
    # @param options [Hash] as_json options.
    #
    # @return [void]
    def json(data, options = {})
      code = options.delete(:status)
      root = options.delete(:root)
      meta = options.delete(:meta)

      status(code) if code
      type(:json)
      write(data) if data.is_a?(::String)

      if data.respond_to?(:as_json)
        data = data.as_json(options)
      elsif data.respond_to?(:map!)
        data.map! { |obj|
          obj.respond_to?(:as_json) ? obj.as_json(options) : obj
        }
      end

      if root
        data = { root => data }
        data[:meta] = meta if meta
      end

      write(@json_renderer.call(data))
    end

    # Finishes the response and returns a rack response endpoint.
    #
    # @return [Array]
    private def finish
      if [204, 205, 304].include?(@status)
        @header.delete CONTENT_TYPE
        @header.delete CONTENT_LENGTH
        @body = []
      else
        unless @header[CONTENT_LENGTH]
          @header[CONTENT_LENGTH] = @body.join.bytesize.to_s
        end

        @header[CONTENT_TYPE] = @content_type
      end

      [@status, @header, @body]
    end
  end
end
