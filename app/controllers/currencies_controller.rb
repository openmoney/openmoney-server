######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class CurrenciesController < ApplicationController
  include OpenMoneyHelper

  # GET /currencies/new
  def new
  end

  # GET /currencies/join
  def join
  end

  # POST /currencies/join
  def join_request
    @event = Event.create(
     {:event_type => "JoinCurrency",
      :specification => {
        "currency" => params[:currency],
        "account" => params[:account],
       }.to_yaml
     }
    )
    if @event.enmesh && @event.save
      flash[:notice] = "#{params[:account]} has joined #{params[:currency]}"
      params[:account] = ''
    end
    render :action => "join"
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
        currency_spec = default_mutual_credit_currency(params[:taxable],params[:unit])
      when "reputation"
        r = { 'type' => 'integer',
          'description' => {
            'en' => 'Rate',
            'es' => 'Califique'
          }
        }
        r['values_enum'] = {
      		"2qual" => {
            'en' => [['Good',1],['Bad',2]],
            'es' => [['Bueno',1],['Malo',2]],
          },
      		"2yesno" => {
      		  'en' => [['Yes',2],['No',1]],
      		  'es' => [['Si',2],['No',1]],
      		},
      		"3qual" => {
      		  'en' => [['Good',3],['Average',2],['Bad',1]],
      		  'es' => [['Bueno',3],['Mediano',2],['Malo',1]],
      		},
      		"4qual" => {
      		  'en' => [['Excellent',4],['Good',3],['Average',2],['Bad',1]],
      		  'es' => [['Excellente',4],['Bueno',3],['Mediano',2],['Malo',1]],
      		},
      		"3stars" => [['***',3],['**',2],['*',1]],
      		"4stars" => [['****',4],['***',3],['**',2],['*',1]],
      		"5stars" => [['*****',5],['****',4],['***',3],['**',2],['*',1]],
      		"3" => (1..3).to_a,
      		"4" => (1..4).to_a,
      		"5" => (1..5).to_a,
      		"10" => (1..10).to_a
          }[params[:rating_type]]
          
        r['type'] = 'integer'
        r['description'] = {
            'en' => 'Rating',
            'es' => 'Calificacíon'
          }
    
        currency_spec['fields'] = {
        	'rate' => {
            'type' => 'submit',
            
        	},
          'rating' => r,
        }
      	currency_spec['summary_type'] = 'mean(rating)'
      	currency_spec['input_form'] = {
      	  'en' => ":declaring_account rates :accepting_account as :rating :rate",
      	  'es' => ":declaring_account califica :accepting_account como :rating :rate"
      	}
      	currency_spec['summary_form'] = {
      	  'en' => ":Overall rating: :mean_accepted (from :count_accepted total ratings)",
          'es' => "Calificacíon: :mean_accepted (de :count_accepted calificacíones)"
      	}        
    	end  
    end
    
    @event = Event.create(
     {:event_type => "CreateCurrency",
      :specification => {
        "credentials" => {params[:parent_context] => {:tag => params[:tag], :password=>params[:password]}},
        "parent_context" => params[:parent_context],
        "name" => params[:name],
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
