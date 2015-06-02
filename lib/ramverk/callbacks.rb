# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
  module Callbacks
    # @api private
    # @see http://www.ruby-doc.org/core/Module.html#method-i-included
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include ::ClassAttribute
        class_attribute :_before_callbacks, :_skip_before_callbacks
        self._before_callbacks = {}
        self._skip_before_callbacks = {}
      end
    end

    module ClassMethods
      # Adds a before filter that's run before the requested action.
      #
      # @example
      #   # Runs do_this before all actions in the current controller
      #   before :do_this
      #
      #   # Runs :do_this only on the action called :index
      #   before :do_this, only: :index
      #
      #   # Runs :do_this on all actions except :index and :create
      #   before :do_this, except: [:index, :create]
      #
      def before(*callbacks, except: nil, only: nil)
        callbacks.each do |cb|
          _before_callbacks[cb] = build_callback_params(except, only)
        end
      end

      # Skips an already defined callback. Mostly created inside a parent
      # router.
      #
      #
      def skip_before(*callbacks, except: nil, only: nil)
        callbacks.each do |cb|
          _skip_before_callbacks[cb] = build_callback_params(except, only)
        end
      end

      # @api private
      private def build_callback_params(except, only)
        { except: except ? Array(except) : nil,
          only: only ? Array(only) : nil }
      end
    end

    # @api private
    # @see Ramverk::Router#process_action
    private def process_action(action)
      run_callbacks(
        self.class._before_callbacks,
        self.class._skip_before_callbacks,
        action
      )

      super
    end

    # @api private
    private def run_callbacks(callbacks, skips, action)
      callbacks.each do |method, opts|
        if skip_opts = skips[method]
          next if skip_opts[:only]   && skip_opts[:only].include?(action)
          next if skip_opts[:except] && !skip_opts[:except].include?(action)
        end

        next if opts[:only]   && !opts[:only].include?(action)
        next if opts[:except] && opts[:except].include?(action)
        send(method)
      end
    end
  end
end
