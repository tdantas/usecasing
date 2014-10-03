require 'spec_helper'
require 'mocks/for_invocation_order'
require 'mocks/for_skip'
require 'mocks/for_context_helpers'
require 'mocks/for_invoke'

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


    it 'subclass adds dependency from subclass to superclass' do

      SuperClassDependency =  Class.new(UseCase::Base)
      UseCaseSuperClass = Class.new(UseCase::Base) do
        depends SuperClassDependency
      end

      SubClassDependency = Class.new(UseCase::Base)
      UseCaseSubClass = Class.new(UseCaseSuperClass) do
        depends SubClassDependency
      end

      expect(UseCaseSubClass.dependencies).to eql([SubClassDependency, SuperClassDependency])
      #idempotent operation
      expect(UseCaseSubClass.dependencies).to eql([SubClassDependency, SuperClassDependency])

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

    it 'receives a hash and create a execution context' do

      SendEmailUseCase = Class.new(UseCase::Base) do
        def perform
          context.sent = 'sent'
        end
      end

      ctx = SendEmailUseCase.perform({email: 'thiago.teixeira.dantas@gmail.com' })
      expect(ctx.sent).to eql('sent')
      expect(ctx.email).to eql('thiago.teixeira.dantas@gmail.com')
    end

    it 'raises exception when params is neither context or a hash' do
      UseCaseArgumentException = Class.new(UseCase::Base)
      expect{ UseCaseArgumentException.perform(Object.new) }.to raise_error(ArgumentError)
    end

    it 'accepts a hash' do
      UseCaseArgumentHash = Class.new(UseCase::Base)
      expect{ UseCaseArgumentHash.perform({}) }.not_to raise_error
    end

    it 'accepts other context' do
      UseCaseArgumentContext = Class.new(UseCase::Base)
      expect{ UseCaseArgumentContext.perform(UseCase::Context.new) }.not_to raise_error
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
      end

      FinalUseCase = Class.new(UseCase::Base) do
        depends CyclicSecond
      end

      expect { FinalUseCase.perform }.to raise_error(StandardError, /cyclic detected/)

    end

  end

  context '##perfoms execution chain' do
    it 'executes in lexical order cascading context among usecases' do

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


    it 'stops the flow when failure happen' do

      FirstUseCaseFailure = Class.new(UseCase::Base) do
        def perform
          context.first = context.first_arg
        end
      end

      SecondUseCaseFailure = Class.new(UseCase::Base) do

        def perform
          context.second = context.second_arg
          failure(:second, 'next will not be called')
        end

      end

      ThirdUseCaseFailure = Class.new(UseCase::Base) do
        def perform
          context.third = true
        end
      end

      UseCaseFailure = Class.new(UseCase::Base) do
        depends FirstUseCaseFailure, SecondUseCaseFailure, ThirdUseCaseFailure
      end

      ThirdUseCaseFailure.any_instance.expects(:perform).never
      UseCaseFailure.perform

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


  context 'rolling back the flow' do

    it 'rollback without dependencies' do

      UseCaseWithRollback = Class.new(UseCase::Base) do

        def perform
          failure(:rollback, 'must be called')
        end

        def rollback
          context.rollback_executed = 'true'
        end

      end

      context = UseCaseWithRollback.perform
      expect(context.rollback_executed).to eql('true')

    end

    it 'in reverse order of execution' do
      order = 0

      UseCaseWithRollbackOrderDepdens = Class.new(UseCase::Base) do
        define_method :rollback do
          order += 1
          context.first_rollback = order
        end

      end

      UseCaseWithRollbackOrder = Class.new(UseCase::Base) do
        depends UseCaseWithRollbackOrderDepdens

        def perform
          failure(:rollback, 'error')
        end

        define_method :rollback do
          order += 1
          context.second_rollback = order
        end
      end

      context = UseCaseWithRollbackOrder.perform
      expect(context.first_rollback).to  eql(1)
      expect(context.second_rollback).to  eql(2)
    end


    it 'only rollbacks usecase that ran' do

      UseCaseFailRanThird = Class.new(UseCase::Base) do

        def rollback
          context.rollback_third = 'true'
        end

      end

      UseCaseFailRanSecond = Class.new(UseCase::Base) do

        def rollback
          context.rollback_second = 'true_2'
        end

      end

      UseCaseFailRanFirst = Class.new(UseCase::Base) do
        depends UseCaseFailRanSecond

        def perform
          failure(:rollback, 'error')
        end

        def rollback
          context.rollback_first = 'true_1'
        end

      end

      UseCaseFailRan = Class.new(UseCase::Base) do
        depends UseCaseFailRanFirst, UseCaseFailRanThird
      end

      context = UseCaseFailRan.perform
      expect(context.rollback_third).to_not be
      expect(context.rollback_second).to be
      expect(context.rollback_first).to be

    end

  end

  context 'stopping the flow' do

    FirstCase = Class.new(UseCase::Base) do
      def perform
        context.wizzard_name = "Gandalf"
      end
    end

    StopCase = Class.new(UseCase::Base) do
      def perform
        context.result = "YOUUUU SHHHAAALLLL NOOOTTTT PASSSSSS!"
        stop!
      end
    end

    UnachievableCase = Class.new(UseCase::Base) do
      def perform
        context.result = "Still here! Muahaha!"
      end
    end

    Base = Class.new(UseCase::Base) do
      depends FirstCase, StopCase, UnachievableCase
    end

    let(:subject) { Base.perform }

    it 'returns variables inserted by first dependency' do
      expect(subject.wizzard_name).to eq("Gandalf")
    end

    it 'does not have variables inserted by unachievable case' do
      expect(subject.result).to eq("YOUUUU SHHHAAALLLL NOOOTTTT PASSSSSS!")
    end

    it 'is successfull' do
      expect(subject.success?).to be_true
    end
  end


  describe '#before' do

    it 'calls "before" method before perform' do
      BeforeUsecasing = Class.new(UseCase::Base) do

        def before
          context.before = true
        end

        def perform
           raise 'Should be called' unless context.before
        end
      end

      expected = BeforeUsecasing.perform
      expect(expected.before).to eql(true)
    end

  end

  describe '.context_reader' do
    context 'given a usecase that defines a context_reader for :books' do
      before { @context = ReaderCase.perform(books: 'books') }

      it 'it creates a reader helper to context.books' do
        expect(@context.success?).to eq(true)
      end
    end
  end

  describe '.context_writer' do
    context 'given a usecase that defines a context_writer for :books' do
      before { @context = WriterCase.perform }

      it 'it creates a writer helper to context.books' do
        expect(@context.books).to eq('books')
      end
    end
  end

  describe '.context_accessor' do
    context 'given a usecase that defines a context_accessor for :books' do
      before { @context = AccessorCase.perform }

      it 'it creates a reader helper to context.books' do
        expect(@context.success?).to eq(true)
      end

      it 'it creates a writer helper to context.books' do
        expect(@context.books).to eq('booooooooks')
      end
    end
  end

  describe '#skip!' do
    context 'given a usecase that defines a #before and #perform and is dependent on another usecase' do
      context 'configured with execution order before->depends->perform (before_depends = true)' do
        before { UseCase.configure { |c| c.before_depends = true } }
        after { UseCase.reset_configuration }

        context 'when skip! is invoked in #before' do
          before { @context = SkipCase1.perform(array: []) }

          it 'runs code in #before' do
            expect(@context.array[0]).to eq('SkipCase1#before')
          end

          it 'it does not run any #befores and #performs in current usecase and dependent usecase' do
            expect(@context.array.count).to eq(1)
          end
        end

        context 'when skip! is invoked in #before in dependent usecase' do
          before { @context = SkipCase2.perform(array: []) }

          it 'executes #before of usecase' do
            expect(@context.array).to include('SkipCase2#before')
          end

          it 'executes #perform of usecase' do
            expect(@context.array).to include('SkipCase2#perform')
          end

          it 'runs code in dependent usecases #before' do
            expect(@context.array).to include('DependentCase#before')
          end

          it 'does not run neither #perform nor dependent usecases of dependent usecase' do
            expect(@context.array.count).to eq(3)
          end
        end
      end
    end
  end

  describe '#invoke!' do
    context 'when method is invoked with a usecase as argument' do
      before { @context = InvokeCase1.perform(array: []) }

      it 'it invokes that usecase with current context' do
        expect(@context.array).to include('DependentCase#before')
        expect(@context.array).to include('DependentCase#perform')
      end
    end

    context 'when method is invoked with more than one usecase' do
      before { @context = InvokeCase2.perform(array: []) }

      it 'it invokes all usecases with current context' do
        expect(@context.array).to include('DependentCase1#before')
        expect(@context.array).to include('DependentCase1#perform')
        expect(@context.array).to include('DependentCase2#before')
        expect(@context.array).to include('DependentCase2#perform')
      end
    end
  end

  describe 'invocation order' do
    context 'given a usecase that defines a before and perform and dependent on another usecase' do
      context 'configured with execution order before->depends->perform (before_depends = true)' do
        before { UseCase.configure { |c| c.before_depends = true } }
        after { UseCase.reset_configuration }

        before { @context = InvocationOrderCase.perform(array: []) }

        it '#before in usecase invoked first' do
          expect(@context.array[0]).to eq('InvocationOrderCase#before')
        end

        it '#before in dependent usecases is invoked second' do
          expect(@context.array[1]).to eq('DependentCase#before')
        end

        it '#perform in dependent usecase is invoked third' do
          expect(@context.array[2]).to eq('DependentCase#perform')
        end

        it '#perform in usecase is invoked last' do
          expect(@context.array[3]).to eq('InvocationOrderCase#perform')
        end
      end
    end
  end

end