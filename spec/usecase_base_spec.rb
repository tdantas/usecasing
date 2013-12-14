require 'spec_helper'

describe UseCase::Base do

  context "depends" do 

    it 'initialize without any dependency' do 
      AppUseCaseInitialize = Class.new(UseCase::Base)
      expect(AppUseCaseInitialize.dependencies).to be_empty
    end

    it "adds usecase dependency" do
      AppOtherUseCase = Class.new
      AppUseCase = Class.new(UseCase::Base) do 
        depends AppOtherUseCase
      end

      expect(AppUseCase.dependencies).to eql([AppOtherUseCase])
    end


    it 'subclass adds dependency from superclass to subclass' do

      SuperClassDependency =  Class.new(UseCase::Base)
      UseCaseSuperClass = Class.new(UseCase::Base) do 
        depends SuperClassDependency
      end

      SubClassDependency = Class.new(UseCase::Base)
      UseCaseSubClass = Class.new(UseCaseSuperClass) do 
        depends SubClassDependency
      end

      expect(UseCaseSubClass.dependencies).to eql([SuperClassDependency, SubClassDependency])
      #idempotent operation
      expect(UseCaseSubClass.dependencies).to eql([SuperClassDependency, SubClassDependency])

    end


  end


  context '##perform' do 

    it 'call instance #perform method' do 
      AppUseCaseInstance = Class.new(UseCase::Base) do 
        def perform
          #some business rule here
        end
      end
      AppUseCaseInstance.any_instance.expects(:perform).once
      AppUseCaseInstance.perform
    end

    it 'receives receives a hash and create a execution context' do 
      SendEmailUseCase = Class.new(UseCase::Base) do 
        def perform
          context.sent = 'sent'
        end
      end
      ctx = SendEmailUseCase.perform({email: 'thiago.teixeira.dantas@gmail.com' })
      expect(ctx.sent).to eql('sent')
      expect(ctx.email).to eql('thiago.teixeira.dantas@gmail.com')
    end

    it 'must receive an hash' do 
      UseCaseArgumentException = Class.new(UseCase::Base)
      expect{ UseCaseArgumentException.perform(Object.new) }.to raise_error(ArgumentError)
    end

    it 'with success when usecase do not register failure' do 
      pending
    end

    it 'fail when usecase register failure' do 
      pending
    end


    it 'detects cyclic' do 

      CyclicFirst = Class.new(UseCase::Base) 
      CyclicSecond = Class.new(UseCase::Base) do 
        depends CyclicFirst
      end

      CyclicFirst.instance_eval do
        depends CyclicSecond
        puts self.dependencies
      end

      FinalUseCase = Class.new(UseCase::Base) do 
        depends CyclicSecond
      end

      expect { FinalUseCase.perform }.to raise_error(StandardError)

    end
   
  end

  context '##perfoms execution chain' do 
    it 'executes in lexical order' do
      FirstUseCase = Class.new(UseCase::Base) do 
        def perform
          context.first = context.first_arg
        end
      end
      
      SecondUseCase = Class.new(UseCase::Base) do 
        def perform
          context.second = context.second_arg
        end
      end 

      UseCaseChain = Class.new(UseCase::Base) do 
        depends FirstUseCase, SecondUseCase
      end

      ctx = UseCaseChain.perform({:first_arg => 1, :second_arg => 2})
      expect(ctx.first).to  eql(1)
      expect(ctx.second).to eql(2)
    end
  end

  context '#perform' do
    it 'receive an Context instance' do 
      InstanceUseCase = Class.new(UseCase::Base) do 
        def perform
          context.executed = true
        end
      end
      ctx = UseCase::Context.new
      InstanceUseCase.new(ctx).perform
      expect(ctx.executed).to be_true
    end 
  end

end