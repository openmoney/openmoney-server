##
# A wrapper that allows instance variables to be manipulated using +[]+ and
# +[]=+

module Spec
  module Rails
    module Expectations
      class IvarProxy #:nodoc:

        ##
        # Wraps +object+ allowing its instance variables to be manipulated.

        def initialize(object)
          @object = object
        end

        ##
        # Retrieves +ivar+ from the wrapped object.

        def [](ivar)
          @object.instance_variable_get "@#{ivar}"
        end

        ##
        # Sets +ivar+ to +val+ on the wrapped object.

        def []=(ivar, val)
          @object.instance_variable_set "@#{ivar}", val
        end

      end
    end
  end
end

