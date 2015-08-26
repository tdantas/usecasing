module UseCase

  module BaseClassMethod

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def depends(*deps)
        @dependencies ||= []
        @dependencies.push(*deps)
      end

      def no_rollback_on_failure
        @rollback_on_failure = false
      end

      def rollback_on_failure?
        @rollback_on_failure = true if @rollback_on_failure.nil?
        @rollback_on_failure
      end

      def dependencies
        return [] unless superclass.ancestors.include? UseCase::Base
        value = (@dependencies && @dependencies.dup || []).concat(superclass.dependencies)
        value
      end

      def perform(ctx = { })
        tx(ExecutionOrder.run(self), ctx) do |usecase, context|
          instance = usecase.new(context)
          instance.tap do | me |
            me.before
            me.perform
          end
        end
      end

      private

      def tx(execution_order, context)
        ctx = (context.is_a?(Context) ? context : Context.new(context))
        executed = []
        no_rollback = false
        execution_order.each do |usecase|
          break if !ctx.success? || ctx.stopped?
          no_rollback = !usecase.rollback_on_failure?
          executed.push(usecase)
          yield usecase, ctx
        end
        rollback(executed, ctx) unless ctx.success? || no_rollback
        ctx
      end

      def rollback(execution_order, context)
        execution_order.each do |usecase|
          usecase.new(context).rollback
        end
        context
      end

    end #ClassMethods
  end #BaseClassMethod

  class Base

    include BaseClassMethod

    attr_reader :context
    def initialize(context)
      @context = context
    end

    def before;  end
    def perform;  end
    def rollback; end

    def stop!
      context.stop!
    end

    def failure(key, value)
      @context.failure(key, value)
    end

  end
end