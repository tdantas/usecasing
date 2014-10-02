module UseCase

  class Context

    class Errors

      def initialize
        @errors = Hash.new { |h,k| h[k.to_sym] = [] }
      end

      def all(delimiter= ", ", &block)
        values = @errors.map {|key, value| value }.flatten
        if block_given?
          values.each &block
        else
          values.join(delimiter)
        end
      end

      def [](index)
        @errors[index.to_sym]
      end

      def push(key, value)
        @errors[key.to_sym].push(value)
      end

      def empty?
        @errors.keys.empty?
      end

    end

    attr_accessor :errors

    def initialize(hash = {})
      raise ArgumentError.new('Must be a Hash') unless hash.is_a? ::Hash 
      @values = symbolyze_keys(hash)
      @errors = Errors.new
    end

    def method_missing(method, *args, &block)
      return @values[extract_key_from(method)] = args.first if setter? method
      @values[method]
    end

    def respond_to?(method, include_all = false)
      @values.keys.include?(method.to_sym)
    end

    def success?
      @errors.empty?
    end

    def failure(key, value)
      @errors.push(key, value)
    end

    private
      def setter?(method)
        !! ((method.to_s) =~ /=$/)
      end

      def extract_key_from(method)
        method.to_s[0..-2].to_sym
      end

      def symbolyze_keys(hash)
        hash.keys.reduce({ }) do |acc, key|
          acc[key.to_sym] = hash[key]
          acc
        end
      end

  end

end