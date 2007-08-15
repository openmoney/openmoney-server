class ClientsController < ApplicationController
  # GET /clients/
  def show
    setup_currency
    @client = params[:client]
    @account = params[:account]
    @account ||= 'zippy^us'
    @accounts = ['zippy^us','eric^cc.ny.us']
#  	<%= Entity.find(:all, :conditions => "entity_type = 'account' ").collect{|e| o = e.omrl.chop; link_to o,"/clients/#{@client}/" << o.gsub(/\./,'%2E')  }.join("</li><li>")%>
  end
  
  # POST /clients/
  def ack
  end
  
  def setup_currency
    @currency_omrl = params[:currency]
    @currency_omrl ||= 'bucks^us'
    @currency = Entity.find_by_omrl(@currency_omrl)
    @params = {"declaring_account" => params[:declaring_account],"accepting_account" => params[:accepting_account]}
    @params.merge!(params[:flow_spec]) if params[:flow_spec]
  end
  
end
