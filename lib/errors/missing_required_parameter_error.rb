module UseCase
  class MissingRequiredParameterError < StandardError
    attr_reader :param

    def initialize(param)
      @param = param
      super("#{param} is not a context key")
    end
  end
end
