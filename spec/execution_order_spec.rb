require 'spec_helper'

describe UseCase::ExecutionOrder do

  context "with only one node" do
    EOFirst = Class.new(UseCase::Base)

    context 'with default before_depends configuration' do
      before { @execution_order = UseCase::ExecutionOrder.run(EOFirst) }

      it 'returns execution order with one node' do
        expect(@execution_order.count).to eql(1)
      end

      it 'first position has execution node with EOFirst as use_class' do
        expect(@execution_order[0].use_case_class).to eql(EOFirst)
      end
    end
  end

  context "with two nodes" do
    EODepdency = Class.new(UseCase::Base)
    EODependent = Class.new(UseCase::Base) { depends EODepdency }

    context 'with default before_depends configuration' do
      before { @execution_order = UseCase::ExecutionOrder.run(EODependent) }

      it 'returns execution order with two nodes' do
        expect(@execution_order.count).to eq(2)
      end

      it 'returns the dependency first' do
        expect(@execution_order[0].use_case_class).to eql(EODepdency)
      end

      it 'returns the dependent use case second' do
        expect(@execution_order[1].use_case_class).to eql(EODependent)
      end
    end
  end

  context 'with repeated nodes' do
    EORepeatedSMS = Class.new(UseCase::Base)
    EOAlert = Class.new(UseCase::Base) { depends EORepeatedSMS }
    EOCreate = Class.new(UseCase::Base) { depends EOAlert, EORepeatedSMS }

    context 'with default before_depends configuration' do
      before { @execution_order = UseCase::ExecutionOrder.run(EOCreate) }

      it 'returns execution order with 4 nodes'  do
        expect(@execution_order.count).to eql(4)
      end
    end
  end
end