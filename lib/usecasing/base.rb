module UseCase

  module BaseClassMethod

    def depends(*deps)
      @dependencies ||= []
      @dependencies.push(*deps)
    end

    def dependencies
      return [] unless superclass.ancestors.include? UseCase::Base
      value = (@dependencies && @dependencies.dup || []).concat(superclass.dependencies)
      value
    end

    def perform(context = {})
      context = Context.new(context)
      execution_order = build_execution_order(self, {})
      execution_order.each do |usecase|
        break unless context.success?
        usecase.new(context).perform 
      end

      context
    end

    private

    def build_execution_order(start_point, visited)
      raise StandardError.new("cyclic detected: #{start_point} in #{self}") if visited[start_point]
      visited[start_point] = true
      return [start_point] if start_point.dependencies.empty?

      start_point.dependencies.each do |point|
        build_execution_order(point, visited).unshift point
      end

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