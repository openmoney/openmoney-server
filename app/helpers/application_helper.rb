# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def currency_select(html_field_name,selected,account = nil)
    c = Entity.find(:all, :conditions => "entity_type = 'currency' ").collect{|e| e.omrl.chop}
    select_tag(html_field_name,options_for_select(c,selected))
  end

  def contexts_select(html_field_name,selected)
    c = Entity.find(:all, :conditions => "entity_type = 'context' ").collect{|e| e.omrl.chop}
    select_tag(html_field_name,options_for_select(c,selected))
  end
  
  def unit_of_measure_select(html_field_name,selected = nil)
    select_tag(html_field_name, <<-EOHTML
		<option value="USD">US Dollar ($)</option>
		<option value="EUR">Euro (&euro;)</option>
		<option value="CAD">Canadian Dollar ($)</option>
		<option value="AUD">Australian Dollar ($)</option>
		<option value="NZD">New Zeland Dollar ($)</option>
		<option value="S">Sterling Pound (&pound;)</option>
		<option value="MXP">Mexican Peso (p)</option>
		<option value="YEN">Yen (&yen;)</option>
		<option value="CHY">Yuan</option>
		<option value="T-h">Time:hours (h)</option>
		<option value="T-m">Time:minutes (h)</option>
		<option value="kwh">Kilowatt Hours (kwh)</option>
		<option value="other">other--see description (&curren;)</option>
    EOHTML
    )
  end
  
  def input_form(currency,declaring_account=nil,language = "en")
    spec = YAML.load(@currency.specification)
    base_field_spec = {"submit" => "submit","USD" => 'unit'}
    if spec["fields"]
      field_spec = spec["fields"]
    else
      field_spec = {"amount" => "float", "description" => "text"}
    end
    field_spec = base_field_spec.merge(field_spec)
#    return spec.inspect
    form = spec["input_form"][language] if spec["input_form"]
    form = ":declaring_account acknowledges :accepting_account for :description in the amount of :USD:amount :submit" if !form
    form.gsub(/:([a-zA-Z-0-9_]+)/) {|m| 
      if $1 == 'declaring_account' && declaring_account
        declaring_account
      else
        render_field($1,field_spec)
      end
    }
  end

  def render_field(field_name,field_spec)

    field_type = field_spec[field_name]
    html_field_name = "flow_spec[#{field_name}]"
    case 
    when field_type.is_a?(Array)
      select_tag(html_field_name,options_for_select(field_type,@params[field_name]))
    when field_type == "boolean"
      select_tag(html_field_name,options_for_select([["Yes", "Y"], ["No", "N"]],@params[field_name]))
    when field_type == "submit"
      submit_tag(field_name.gsub(/_/,' '))
    when field_type == "text"
      text_field_tag (html_field_name,@params[field_name])
    when field_type == "float"
      text_field_tag (html_field_name,@params[field_name])
    when field_type == "unit"
      {
        'USD'=>'$',
        'EUR'=>'&euro;',
        'CAD'=>'$',
        'AUD'=>'$',
        'NZD'=>'$',
        'S'=>'&pound;',
        'MXP'=>'p',
        'YEN'=>'&yen;',
        "CHY"=>'Yuan',
        'T-h'=>'h',
        'T-m'=>'h',
        'kwh'=>'kwh',
        'other'=>'&curren;'
      }[field_name]
    else
      text_field_tag (field_name,@params[field_name])
    end
  end  
end
