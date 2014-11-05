# Because it's used by Sheller
require "open3"

require "guard/ui"

require "guard/internals/tracing"

module Guard
  # @private api
  module Internals
    class Debugging
      class << self
        TRACES = [
          [Kernel, :system],
          [Kernel, :`],
          [Open3, :popen3]
        ]

        # Sets up debugging:
        #
        # * aborts on thread exceptions
        # * Set the logging level to `:debug`
        # * traces execution of Kernel.system and backtick calls
        def start
          return if @started ||= false
          @started = true

          Thread.abort_on_exception = true

          ::Guard::UI.level = Logger::DEBUG

          TRACES.each { |mod, meth| _trace(mod, meth, &method(:_notify)) }
          @traced = true
        end

        def stop
          return unless @started ||= false
          ::Guard::UI.level = Logger::INFO
          _reset
        end

        private

        def _notify(*args)
          ::Guard::UI.debug "Command execution: #{args.join(" ")}"
        end

        # reset singleton - called by tests
        def _reset
          @started = false
          return unless @traced
          TRACES.each { |mod, meth| _untrace(mod, meth) }
          @traced = false
        end

        def _trace(mod, meth, &block)
          ::Guard::Internals::Tracing.trace(mod, meth, &block)
        end

        def _untrace(mod, meth)
          ::Guard::Internals::Tracing.untrace(mod, meth)
        end
      end
    end
  end
end
