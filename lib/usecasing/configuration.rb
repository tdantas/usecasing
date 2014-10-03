module UseCase
  class Configuration
    attr_accessor :before_depends

    def initialize
      # indicates which of the execution orders should use:
      #   - depends -> before -> perform (default, value false)
      #   - before -> depends -> perform (value true)
      @before_depends = false
    end
  end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end