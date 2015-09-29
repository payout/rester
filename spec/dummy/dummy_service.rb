require 'restercom'

module Restercom
  class DummyService < Service
    def echo(*args)
      {
        args:   args[0..-2],
        params: args[-1]
      }
    end

    def echo!(*args)
      echo(*args)
    end

    def bad_body_method(*args)
      lambda { "Do or do not" } # Class.new
    end

    private

    def _a_private_method
    end
  end # DummyService
end # Restercom
