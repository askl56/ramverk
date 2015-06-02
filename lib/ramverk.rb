# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require_relative 'ramverk/version'
require_relative 'ramverk/application'

module Ramverk
  # @api private
  RACK_ENV = 'RACK_ENV'.freeze

  # Root path for the application. It's always the current working directory.
  #
  # @return [Pathname] Application's root.
  #
  # @since 0.2.0
  def self.root
    @root ||= ::Dir.pwd
  end

  # Returns the current environment.
  #
  # @example
  #   Ramverk.env # => :development
  #
  # @return [Symbol]
  def self.env
    @env ||= ENV[RACK_ENV] ? ENV[RACK_ENV].to_sym : :development
  end

  # Check to see if given environment(s) matches the current environment.
  #
  # @example
  #   ENV['RACK_ENV'] = 'test'
  #
  #   Ramverk.env?(:development) # => false
  #   Ramverk.env?(:development, :test) # => true
  #   Ramverk.env?(:test) # => true
  #
  # @param *envs [Array<Symbol>] Environment(s) to match.
  #
  # @return [boolean]
  def self.env?(*envs)
    envs.include?(env)
  end
end
