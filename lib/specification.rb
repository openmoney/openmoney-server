module Specification 
  
  # classes which mix in specification are assumed to be ActiveRecords, or at least be able to
  # recieve the message errors.add
  
  def validate_specification(validations,attribute_name = :specification)
    unless @specification
      begin
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