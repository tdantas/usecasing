require 'set'
require 'tsort'

module UseCase

  class CyclicFinder
    include TSort
    
    def initialize(start_point)
      @start_point = start_point
      @nodes = discover_nodes
    end

    def tsort_each_node(&block)
      @nodes.each &block
    end

    def tsort_each_child(node, &block)
      node.dependencies.each &block
    end

    def cyclic?
      components = strongly_connected_components
      result = components.any?{ |component| component.size != 1 }
      [ result, components.select{|component| component.size != 1 } ]
    end

    private
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