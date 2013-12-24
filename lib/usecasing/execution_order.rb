require 'set'
require 'tsort'

module UseCase

  class ExecutionOrder

    def self.run(start_node)
      any_ciclic, ciclic = CyclicFinder.cyclic?(start_node)
      raise StandardError.new("cyclic detected: #{ciclic}") if any_ciclic
      post_order(start_node, [])
    end

    private
    def self.post_order(node, result)
      return result.push(node) if node.dependencies.empty?
        
      node.dependencies.each do |item|
        post_order(item, result)
      end

      result.push(node)
    end
  end

  class CyclicFinder
    include TSort

    def self.cyclic?(start_point)
      new(start_point).cyclic?
    end
    
    def initialize(start_point)
      @start_point = start_point
      @nodes       = discover_nodes
    end


    def cyclic?
      components = strongly_connected_components
      result = components.any?{ |component| component.size != 1 }
      [ result, components.select{|component| component.size != 1 } ]
    end

    private

    def tsort_each_node(&block)
      @nodes.each &block
    end

    def tsort_each_child(node, &block)
      node.dependencies.each &block
    end
    
    def discover_nodes
      visited = {}
      stack = [@start_point]
      result = Set.new
      until stack.empty?
        node = stack.pop
        result.add node
        stack.push(*(node.dependencies)) if not visited[node]
        visited[node] = true
      end
      return result
    end

  end
end