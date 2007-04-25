dir = File.dirname(__FILE__)

require File.expand_path("#{dir}/context/base")
require File.expand_path("#{dir}/context/functional")
require File.expand_path("#{dir}/context/model")
require File.expand_path("#{dir}/context/controller")
require File.expand_path("#{dir}/context/helper")
require File.expand_path("#{dir}/context/view")

module Spec
  module Rails
    module Runner
      class Context #:nodoc:
      end
    end
  end
end



