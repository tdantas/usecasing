require 'forwardable'

module UseCase

  module BaseClassMethod

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      include Forwardable

      def context_accessor(*args)
        args = args.reduce([]) { |array, arg| array.concat([arg, "#{arg}="]); array }

        def_delegators :context, *args
      end

      def context_writer(*args)
        args = args.reduce([]) { |array, val| array << "#{val}="; array }

        def_delegators :context, *args
      end

      def context_reader(*args)
        def_delegators :context, *args
      end

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
        (ctx.is_a?(Context) ? ctx : Context.new(ctx)).tap do |context|
          execution_nodes = ExecutionOrder.run(self)

          execution_nodes.each do |execution_node|
            break if !context.success? || context.stopped?

            next unless execute_node?(execution_node, context.skipped_node_ids)

            execution_node.execute(context)

            if execution_node.skipped?
              context.skipped_node_ids << execution_node.node_id
            elsif execution_node.for_rollback?
              context.executed.push(execution_node.use_case_class)
            end
          end

          rollback(context.executed, context) unless context.success?
        end
      end

      private

      def execute_node?(execution_node, skipped_node_ids)
        (execution_node.dependent_node_ids & skipped_node_ids).empty?
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

    def skip!
      @skip_use_case = true
    end

    def invoke!(*use_cases)
      use_cases.each { |use_case| use_case.perform(context) }
    end

  end
end