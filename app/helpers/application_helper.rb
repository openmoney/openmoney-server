# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def currency_select(html_field_name,selected)
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
end
