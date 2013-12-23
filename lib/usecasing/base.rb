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
        any_ciclic, ciclic = CyclicFinder.new(self).cyclic?
        raise StandardError.new("cyclic detected: #{ciclic}") if any_ciclic
        execution_order = [] 
        build_execution_order(self, execution_order)
        tx(execution_order, ctx) do |usecase, context| 
          usecase.new(context).perform 
        end
      end

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

      def build_execution_order(node, result)
        return result.push(node) if node.dependencies.empty?
        
        node.dependencies.each do |item|
          build_execution_order(item, result)
        end

        result.push(node)
      end

      # def build_execution_order
      #   stack = [self]
      #   result  = []
      #   visited = {}
        
      #   until stack.empty?
      #     node = stack.last
      #     if(node.dependencies.empty? || visited[node.name])
      #       result.push(stack.pop)
      #     else
      #       stack.push(*(node.dependencies.reverse))
      #       visited[node.name] = true
      #     end
      #   end

      #   return result

      # end

    end #ClassMethods
  end #BaseClassMethod

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