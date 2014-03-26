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
        ctx = Context.new(context)
        executed = []
        execution_order.each do |usecase|
          break unless ctx.success?
          executed.push(usecase)
          yield usecase, ctx
        end
        rollback(executed, ctx) unless ctx.success?
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

    def failure(key, value)
      @context.failure(key, value)
    end
    
  end
end