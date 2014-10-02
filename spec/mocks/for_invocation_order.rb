class InvocationOrderCase < UseCase::Base
  class DependentCase < UseCase::Base
    def before
      context.array << 'DependentCase#before'
    end

    def perform
      context.array << 'DependentCase#perform'
    end
  end

  def before
    context.array << 'InvocationOrderCase#before'
  end

  depends DependentCase

  def perform
    context.array << 'InvocationOrderCase#perform'
  end
end