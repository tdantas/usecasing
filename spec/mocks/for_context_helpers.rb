class ReaderCase < UseCase::Base
  context_reader :books

  def perform
    failure(:failure) unless books == context.books
  end
end

class WriterCase < UseCase::Base
  context_writer :books

  def perform
    self.books = 'books'
  end
end

class AccessorCase < UseCase::Base
  context_accessor :books

  def perform
    return failure(:failure) unless books == context.books

    self.books = 'booooooooks'
  end
end