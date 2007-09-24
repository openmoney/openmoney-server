######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class AcknowledgeFlowController < ApplicationController
  include OpenMoneyHelper

  before_filter :setup_currency, :except => :list

  # GET /acknowledge_flows
  def list
  end
  
  # GET /acknowledge_flow/<currency>
  def show
  end
  
  # POST /acknowledge_flow/<currency>
  def ack
    spec = YAML.load(@currency.specification)
        
    @event = Event.create(
     {:event_type => "AcknowledgeFlow",
      :specification => {
        "ack_password" => params[:password],
        "flow_specification" => params["flow_spec"],
        "declaring_account" => params["declaring_account"],
        "accepting_account" => params["accepting_account"],
        "currency" => @currency_omrl
       }.to_yaml
     }
    )
    if (result = @event.enmesh)
      @event.result = result.to_yaml
      if @event.save
        currency = Entity.find_by_omrl(@currency_omrl)
        flash[:notice] = "Flow acknowledged: #{params["declaring_account"]} " << render_summary(currency.get_specification,params["declaring_account"])
      end
    end
    render :action => "show"
  end
  
  private 
  def setup_currency
    @currency_omrl = params[:currency]
    @currency = Entity.find_by_omrl(@currency_omrl)
    @params = {"declaring_account" => params[:declaring_account],"accepting_account" => params[:accepting_account]}
    @params.merge!(params[:flow_spec]) if params[:flow_spec]
  end
  
end