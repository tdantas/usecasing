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
        execution_order = build_execution_order(self, {})
        tx(execution_order, ctx) do |usecase, context| 
          usecase.new(context).perform 
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

      def build_execution_order(start_point, visited)
        raise StandardError.new("cyclic detected: #{start_point} in #{self}") if visited[start_point]
        visited[start_point] = true
        return [start_point] if start_point.dependencies.empty?

        childrens = start_point.dependencies.each do |point|
          build_execution_order(point, visited).unshift point
        end
        childrens.push(start_point)

      end
    end

  end

  class Base

    include BaseClassMethod

    attr_reader :context
    def initialize(context)
      @context = context
    end

    def perform;  end
    def rollback; end

    def failure(key, value)
      @context.failure(key, value)
    end
    
  end
end