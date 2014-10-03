require 'set'
require 'tsort'
require 'usecasing/configuration'

module UseCase

  class ExecutionOrder

    class ExecutionNode
      attr_reader :dependent_node_ids, :use_case_class, :method_name

      def initialize(dependent_node_ids, use_case_class, method_name)
        @dependent_node_ids = dependent_node_ids
        @use_case_class     = use_case_class
        @method_name        = method_name
      end

      def node_id
        use_case_class.__id__
      end

      # only nodes for method perform are to be rolled back
      def for_rollback?
        method_name == :perform
      end

      def execute(context)
        @instance = use_case_class.new(context)
        @instance.send(method_name)
      end

      def skipped?
        !!@instance.instance_variable_get('@skip_use_case')
      end
    end

    def self.run(start_node)
      any_ciclic, ciclic = CyclicFinder.cyclic?(start_node)
      raise StandardError.new("cyclic detected: #{ciclic}") if any_ciclic
      post_order(start_node, [])
    end

  private

    class << self
      def post_order(use_case_class, result, dependent_node_ids = [])
        # push node id to group ids
        dependent_node_ids.push(use_case_class.__id__)

        if ::UseCase.configuration.before_depends
          post_before use_case_class, result, dependent_node_ids
          post_dependencies use_case_class, result, dependent_node_ids
        else
          post_dependencies use_case_class, result, dependent_node_ids
          post_before use_case_class, result, dependent_node_ids
        end

        # push perform method
        result.push \
          ExecutionNode.new(dependent_node_ids, use_case_class, :perform)
      end

      def post_dependencies(use_case_class, result, dependent_node_ids)
        # parse dependencies use_cases
        use_case_class.dependencies.each do |dependency_use_case|
          post_order(dependency_use_case, result, dependent_node_ids.dup)
        end
      end

      def post_before(use_case_class, result, dependent_node_ids)
        if use_case_class.instance_method(:before).owner != Base
          # only set before method in execution path if it's overridden
          result.push \
            ExecutionNode.new(dependent_node_ids, use_case_class, :before)
        end
      end
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