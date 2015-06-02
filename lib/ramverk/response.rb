# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
  # Response represents an HTTP response.
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  class Response
    # @api private
    CONTENT_TYPE = 'Content-Type'.freeze

    # @api private
    CONTENT_LENGTH = 'Content-Length'.freeze

    # Object intializer. Sets up default values.
    #
    # @param default_headers [Hash] Default headers.
    def initialize(default_header = {})
      @header = default_header
      @status = 200
      @content_type = 'text/plain'
      @body = ['']
    end

    # Setter and getter for content type.
    #
    # @example Setter
    #   response.content_type(:json)
    #
    #   response.type(:json) # alias method
    #
    # @example Getter
    #   type = response.content_type
    #   type # => 'application/json'
    #
    #   response.type # alias method
    #
    # @param [Symbol] New content type.
    #
    # @return [String, Ramverk::Response]
    def content_type(new_type = nil)
      return @content_type unless new_type
      @content_type = ::Rack::Mime::MIME_TYPES[".#{new_type}"]
      self
    end
    alias_method :type, :content_type

    # Setter and getter for response header.
    #
    # @example Get existing header
    #   type = response.header('Content-Type')
    #
    # @example Set single header
    #   response.header('Content-Type', 'application/json')
    #
    # @example Set multiple headers
    #   response.header('Content-Type' => 'application/json')
    #
    # @example Set header using the hash
    #   response.header['Content-Type'] = 'text/xml'
    #
    # @param header [String, Hash] String for getitng or single setting, else hash.
    # @param value [String, nil] String for single setting or nil for mass or getting.
    #
    # @return [String, self]
    def header(header = nil, value = nil)
      return @header[header] if header.is_a?(::String) and value.nil?
      return @header if header.nil?

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
    #   response.set('Hello World')
    #
    # @example Getter
    #   body = response.body
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
    #   response.status(404)
    #
    # @example Getter
    #   status = response.status
    #
    # @param code [Integer, nil] Status code when setting or nil when getting.
    #
    # @return [Integer, self]
    def status(code = nil)
      return @status unless code
      @status = code
      self
    end

    # Writes and finishes the response.
    #
    # @param body [String] Optional body.
    #
    # @return [void]
    def write(body = nil)
      self.body(body) unless body.nil?
      throw :finished, finish
    end

    # Sends a "blank" response body with only status and headers.
    #
    # @param status [Integer] Response status to be sent.
    # @param headers [Hash] Optional response headers.
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
    # @param url [String] Destination.
    #
    # @return void
    def redirect(url)
      @status = 302 unless @status[0] == 3
      @header['Location'] = url
      throw :finished, finish
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
        if @header[CONTENT_LENGTH].nil?
          @header[CONTENT_LENGTH] = @body.join.bytesize.to_s
        end

        @header[CONTENT_TYPE] = @content_type
      end

      [@status, @header, @body]
    end
  end
end
