# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

require 'rack'
require 'class_attribute'

require_relative 'middleware'
require_relative 'configuration'
require_relative 'routers'

module Ramverk
  # Ramverk application.
  #
  # @example
  #   require 'ramverk'
  #
  #   class MyApp < Ramverk::Application
  #   end
  #
  # @author Tobias Sandelius <tobias@sandeli.us>
  class Application
    include ::ClassAttribute

    # @api private
    class_attribute :middleware, :config, :routers

    # Application configuration
    self.config = Configuration.new

    # @api private
    self.routers = Routers.new

    # Middleware builder.
    self.middleware = Middleware.new

    # Environment based configurations.
    #
    # @example
    #   config.security[:clickjacking] = false
    #
    #   configure :development do
    #     config[:raise_errors] = true
    #     config.security[:ip_spoofing] = false
    #   end
    #
    # @param *envs [Array<Symbol>] Environments to set config in.
    # @param &block [Proc] Configuration block.
    #
    # @return [void]
    def self.configure(*envs, &block)
      class_eval(&block) if ::Ramverk.env?(*envs)
    end

    # @see Ramverk::Middleware#use
    def self.use(middleware, *args, &block)
      self.middleware.use(middleware, *args, &block)
    end

    # @see Ramverk::Routers#map
    def self.map(*routers)
      self.routers.map(*routers)
    end

    # Load up application configuration.
    #
    # @return [void]
    def self.load!
      self.config.load!(self)
    end

    # Initialize a new instance of the application.
    #
    # @return [Ramverk::Application]
    def initialize
      self.class.load!
    end

    # Rack compatible endpoint.
    # @api private
    def call(env)
      self.class.middleware.call(env)
    rescue ::Exception => e
      raise e if self.class.config[:raise_errors]
      [500, {}, ['[500] Internal Server Error']]
    end
  end
end
