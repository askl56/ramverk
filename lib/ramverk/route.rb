# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
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
