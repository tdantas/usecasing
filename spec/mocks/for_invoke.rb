class InvokeCase1 < UseCase::Base
  class DependentCase < UseCase::Base
    def before
      context.array << 'DependentCase#before'
    end

    def perform
      context.array << 'DependentCase#perform'
    end
  end

  def perform
    invoke! DependentCase
  end
end

class InvokeCase2 < UseCase::Base
  class DependentCase1 < UseCase::Base
    def before
      context.array << 'DependentCase1#before'
    end

    def perform
      context.array << 'DependentCase1#perform'
    end
  end

  class DependentCase2 < UseCase::Base
    def before
      context.array << 'DependentCase2#before'
    end

    def perform
      context.array << 'DependentCase2#perform'
    end
  end

  def perform
    invoke! DependentCase1, DependentCase2
  end
end