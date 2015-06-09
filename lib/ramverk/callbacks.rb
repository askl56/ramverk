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
    # @author Tobias Sandelius <tobias@sandeli.us>
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
    # @param callbacks [Array<Symbol>] Callbacks to be called before the
    #   action.
    # @param except [Symbol, Array<Symbol>] Callbacks should be run on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be run on the
    #   provided action(s).
    #
    # @return [void]
    def add(*callbacks, except: nil, only: nil)
      build_callback_params(@stack, callbacks, except, only)
    end

    # Skips an already defined callback.
    #
    # @param callbacks [Array<Symbol>] Callbacks to be skipped.
    # @param except [Symbol, Array<Symbol>] Callbacks should be skipped on all
    #   actions except the provided one(s).
    # @param only [Symbol, Array<Symbol>] Callbacks should only be skipped on
    #  the provided action(s).
    #
    # @return [void]
    def skip(*callbacks, except: nil, only: nil)
      build_callback_params(@skips, callbacks, except, only)
    end

    # Runs the callbacks on the given action.
    #
    # @param context [Object] Context the callbacks should be run in.
    # @param action [Symbol] Action/event name.
    #
    # @return [void]
    def run(context, action)
      @stack.each do |cb, opts|
        next if skip?(cb, action)
        next if opts[:only]   && !opts[:only].include?(action)
        next if opts[:except] && opts[:except].include?(action)
        context.send(cb)
      end
    end

    # @api private
    private def skip?(cb, action)
      if skip_opts = @skips[cb]
        return true if !skip_opts[:only]  && !skip_opts[:except]
        return true if skip_opts[:only]   && skip_opts[:only].include?(action)
        return true if skip_opts[:except] && !skip_opts[:except].include?(action)
      end
    end

    # @api private
    private def build_callback_params(stack, callbacks, except, only)
      opts = {
        except: except ? Array(except) : nil,
        only: only ? Array(only) : nil
      }

      callbacks.each { |cb| stack[cb] = opts }
    end
  end
end
