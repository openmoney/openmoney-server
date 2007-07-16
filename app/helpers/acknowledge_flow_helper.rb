module AcknowledgeFlowHelper
  def input_form(currency,language = "en")
    spec = YAML.load(@currency.specification)
    base_field_spec = {"submit" => "submit"}
    if spec["fields"]
      field_spec = spec["fields"]
    else
      field_spec = {"amount" => "float", "description" => "text"}
    end
    field_spec = base_field_spec.merge(field_spec)
#    return spec.inspect
    form = spec["input_form"][language] if spec["input_form"]
    form = ":declaring_account acknowledges :accepting_account for :description in the amount of :amount :submit" if !form
    form.gsub(/:([a-zA-Z-0-9_]+)/) {|m| render_field($1,field_spec)}
  end
  
  def render_field(field_name,field_spec)
    
    field_type = field_spec[field_name]
    html_field_name = "flow_spec[#{field_name}]"
    case 
    when field_type.is_a?(Array)
      select_tag(html_field_name,options_for_select(field_type))      
    when field_type == "boolean"
      select_tag(html_field_name,options_for_select([["Yes", "Y"], ["No", "N"]]))
    when field_type == "submit"
      submit_tag(field_name.gsub(/_/,' '))
    when field_type == "text"
      text_field_tag (html_field_name)
    when field_type == "float"
      text_field_tag (html_field_name)
    else
      text_field_tag (field_name)
    end
  end
end	