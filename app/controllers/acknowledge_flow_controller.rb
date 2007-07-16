######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class AcknowledgeFlowController < ApplicationController
  before_filter :setup_currency
  
  # GET /acknowledge_flow/<currency>
  def show
  end
  
  # POST /acknowledge_flow/<currency>
  def ack
    spec = YAML.load(@currency.specification)
#    raise params.inspect
        
    @event = Event.create(
     {:event_type => "AcknowledgeFlow",
      :specification => {
        "flow_specification" => params["flow_spec"],
        "declaring_account" => params["declaring_account"],
        "accepting_account" => params["accepting_account"],
        "currency" => @currency_omrl
       }.to_yaml
     }
    )
    if @event.enmesh && @event.save
      flash[:notice] = 'Acked!'
    else
      flash[:notice] = "Didn't Ack!"
    end
  end
  
  private 
  def setup_currency
    @currency_omrl = params[:currency]
    @currency = Entity.find_by_omrl(@currency_omrl)
  end
  
end