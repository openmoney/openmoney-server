module Spec
  module Rails
    module Expectations
      class OptsMerger #:nodoc:
        def initialize opts
          @opts = opts
        end
  
        def merge(key)
          return {} if @opts.nil? || @opts.empty?
          if [String, Symbol].include? @opts.first.class
            first = { key => @opts.first.to_s }
            return @opts.size > 1 ? @opts.last.merge(first) : first
          else
            return @opts.last
          end
        end
      end
    end
  end
end