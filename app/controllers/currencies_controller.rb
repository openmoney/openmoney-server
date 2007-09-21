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
