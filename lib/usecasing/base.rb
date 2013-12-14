module UseCase

  module BaseClassMethod

    def depends(*deps)
      @dependencies ||= []
      @dependencies.push(*deps)
    end

    def dependencies
      return [] unless superclass.ancestors.include?(UseCase::Base)
      value = (@dependencies && @dependencies.dup || []).concat(superclass.dependencies)
      value.reverse
    end

    def perform(context = {})
      context = Context.new(context)
      execution_order = Array.new
      tx(context, execution_order) do 
        dependencies_inception(self, context, execution_order, {})
      end
      context
    end

    private

    def tx(watchable, execution_order, &block)
      block.call
      rollback(execution_order, watchable) unless watchable.success?
    end

    def rollback(order, context)
      order.reverse.each do |klass|
        klass.new(context).rollback
      end
    end

    def dependencies_inception(dependency_klass, context, execution_order, visited = {})
      return unless context.success?
      raise StandardError.new("cyclic detected: #{dependency_klass} in #{self}") if visited[dependency_klass]
      visited[dependency_klass] = true
      
      dependency_klass.dependencies.each do |klass|
        dependencies_inception(klass, context, execution_order, visited)
      end
      execution_order.push dependency_klass
      dependency_klass.new(context).perform
    end

  end


  class Base
    extend BaseClassMethod

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