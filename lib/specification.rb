######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

module Specification 
  
  # Classes which mix in Specification are assumed to be ActiveRecords,
  # or at least be able to recieve the message errors.add.  They are also assumed to
  # have a "specification" attribute from which to get the yaml text to be validated
  
  ######################################################################################
  # Specifications are assumed to be hash tables stored as chunks of YAML.
  # This methods makes sure the chunk adheres to the constraints in the validations param
  # which is a hash.  The keys of the validation hash are the parameters of the specifaction 
  # to check, the the value is what must be true about the specification
  #
  #  
  def validate_specification(validations,attribute_name = :specification)
    unless @specification
      begin
        #TODO: we need magic here to use the value of attribute_name instead of
        # assuming that the attribute is called "specification"
        @specification = YAML.load(specification) 
      rescue Exception => e
        errors.add(attribute_name,"specification does not appear to be valid YAML (#{e.to_s})")
      end
    end
    
    unless !errors.empty?
      validations.each do |param,spec|
        case spec
        when :required
          errors.add(attribute_name,"parameter: #{param} is required") if !@specification[param]
        end
      end
    end
  end
  
end