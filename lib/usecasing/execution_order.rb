module UseCase

  class ExecutionOrder

    def self.run(start_node)
      any_ciclic, ciclic = CyclicFinder.new(start_node).cyclic?
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
end