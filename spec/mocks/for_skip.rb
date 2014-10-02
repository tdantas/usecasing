class SkipCase1 < UseCase::Base
  class DependentCase < UseCase::Base
    def before
      context.array << 'DependentCase#before'
    end

    def perform
      context.array << 'DependentCase#perform'
    end
  end

  def before
    context.array << 'SkipCase1#before'
    skip!
  end

  depends DependentCase

  def perform
    context.array << 'SkipCase1#perform'
  end
end

class SkipCase2 < UseCase::Base
  class DependentCase < UseCase::Base
    class DependentCase2 < UseCase::Base
      def before
        context.array << 'DependentCase#before'
      end

      def perform
        context.array << 'DependentCase#perform'
      end
    end

    def before
      skip!
      context.array << 'DependentCase#before'
    end

    depends DependentCase2

    def perform
      context.array << 'DependentCase#perform'
    end
  end

  def before
    context.array << 'SkipCase2#before'
  end

  depends DependentCase

  def perform
    context.array << 'SkipCase2#perform'
  end
end