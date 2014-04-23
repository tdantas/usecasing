require 'spec_helper'

describe UseCase::ExecutionOrder do 

  context "with only one node" do 
    it 'returns post order' do 
      EOFirst = Class.new(UseCase::Base)
      expect(UseCase::ExecutionOrder.run(EOFirst)).to eql([EOFirst])
    end
  end

  context "with two nodes" do 
    it 'returns the dependency first' do 
      EODepdency = Class.new(UseCase::Base)
      EODependent = Class.new(UseCase::Base) do 
        depends EODepdency
      end

      expect(UseCase::ExecutionOrder.run(EODependent)).to eql([EODepdency, EODependent])

    end
  end

  context 'with repeated nodes' do 
    it 'returns duplicated nodes'  do
      EORepeatedSMS = Class.new(UseCase::Base)
      
      EOAlert = Class.new(UseCase::Base) do 
        depends EORepeatedSMS
      end

      EOCreate = Class.new(UseCase::Base) do 
        depends EOAlert, EORepeatedSMS
      end

      expect(UseCase::ExecutionOrder.run(EOCreate)).to eql([EORepeatedSMS, EOAlert, EORepeatedSMS, EOCreate])
    end
  end
end