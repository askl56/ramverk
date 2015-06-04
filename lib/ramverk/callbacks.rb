# This file is part of the Ramverk package.
#
# (c) Tobias Sandelius <tobias@sandeli.us>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Ramverk
  class Callbacks
    # Intitialize a new callback stack.
    #
    # @param callbacks [Hash] Predefined callbacks (used on dup).
    # @param skips [Hash] Predefined skips (used on dup).
    def initialize(callbacks = {}, skips = {})
      @stack = callbacks
      @skips = skips
    end

    # @api private
    # @see http://ruby-doc.org/core-2.2.2/Object.html#method-i-dup
    def dup
      self.class.new(@stack.dup, @skips.dup)
    end

    # Adds a callback to the stack.
    #
    # @param *callbacks [Array<Symbol>] Callbacks to be called before the
    #   action.
    # @param except [Symbol, Array<Symbol>] Callbacks should be run on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be run on the
    #   provided action(s).
    # @param &block [Proc] Callback block (optional).
    #
    # @return [void]
    def add(*callbacks, except: nil, only: nil, &block)
      opts = build_callback_params(except, only)
      callbacks.each { |cb| @stack[cb] = opts }
      @stack[block] = opts if block_given?
    end

    # Skips an already defined callback.
    #
    # @param *callbacks [Array<Symbol>] Callbacks to be skipped.
    # @param except [Symbol, Array<Symbol>] Callbacks should be skipped on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be skipped on
    #  the provided action(s).
    #
    # @return [void]
    def skip(*callbacks, except: nil, only: nil)
      opts = build_callback_params(except, only)
      callbacks.each { |cb| @skips[cb] = opts }
    end

    # Runs the callbacks on the given action.
    #
    # @param context [Object] Context the callbacks should be run in.
    # @param action [Symbol] Action/event name.
    #
    # @return [void]
    def run(context, action)
      @stack.each do |cb, opts|
        is_proc = cb.is_a?(::Proc)

        if !is_proc && skip_opts = @skips[cb]
          next if !skip_opts[:only]  && !skip_opts[:except]
          next if skip_opts[:only]   && skip_opts[:only].include?(action)
          next if skip_opts[:except] && !skip_opts[:except].include?(action)
        end

        next if opts[:only]   && !opts[:only].include?(action)
        next if opts[:except] && opts[:except].include?(action)

        is_proc ? context.instance_eval(&cb) : context.send(cb)
      end
    end

    # @api private
    private def build_callback_params(except, only)
      { except: except ? Array(except) : nil,
        only: only ? Array(only) : nil }
    end
  end
end
