class CurrenciesController < ApplicationController

  # GET /currencies/new
  def new
  end
  
  # POST /currencies/
  def create
    currency_spec = {
      "description" => params[:description]
    }
    if params[:use_advanced]
      currency_spec.merge!(YAML.load(params[:currency_spec]))
    else
      case params[:type]
      when "mutual_credit"
        currency_spec['fields'] = {
          'amount' => 'float',
        	'description' => 'text',
        	'acknowledge_flow' => 'submit'
        }
        currency_spec['fields']['taxable'] = 'boolean' if params[:taxable]
      	currency_spec['summary_type'] = 'balance(amount)'
      	currency_spec['input_form'] = {
      	  'en' => ":declaring_account acknowledges :accepting_account for :description in the amount of  :amount #{params[:taxable] ? '(taxable :taxable) ' : ''}:acknowledge_flow"
      	  }
      when "reputation"
        r = {
      		"2qual" => [['Good',2],['Bad',1]],
      		"2yesno" => [['Yes',2],['No',1]],
      		"3qual" => [['Good',3],['Average',2],['Bad',1]],
      		"4qual" => [['Excellent',4],['Good',3],['Average',2],['Bad',1]],
      		"3stars" => [['***',3],['**',2],['*',1]],
      		"4stars" => [['****',4],['***',3],['**',2],['*',1]],
      		"5stars" => [['*****',5],['****',4],['***',3],['**',2],['*',1]],
      		"3" => (1..3).to_a,
      		"4" => (1..4).to_a,
      		"5" => (1..5).to_a,
      		"10" => (1..10).to_a
          }[params[:rating_type]]
          
        currency_spec['fields'] = {
          'rating' => r,
        	'rate' => 'submit'
        }
      	currency_spec['summary_type'] = 'mean(rating)'
      	currency_spec['input_form'] = {
      	  'en' => ":declaring_account rates :accepting_account as :rating :rate"
      	}
    	end  
    end
    
    @event = Event.create(
     {:event_type => "CreateCurrency",
      :specification => {
        "parent_context" => params[:parent_context],
        "name" => params[:name],
        "originating_account" => params[:originating_account],
        "currency_specification" => currency_spec
       }.to_yaml
     }
    )
    if @event.enmesh && @event.save
      flash[:notice] = 'The currency was created!'
      params[:name] = ''
      params[:description] = ''
    end
    render :action => "new"
  end
end
