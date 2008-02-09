######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################


# TODO the implementation of the filtering parameters here is totally non-scalable
# gotta figure out how to fix that.

class EntitiesController < ApplicationController
  
  before_filter :check_for_entity_type
  # GET /entities
  # GET /entities.xml
  def index
    @entities = Entity.find(:all,@conditions)
    options = {:methods => [:omrl]}
    if params[:entity_type] == "currencies"
      if params[:used_by]
        account_omrl = OMRL.new(params[:used_by]).to_s
        @entities = @entities.collect {|e| e.links.any?{|l| l.link_type == 'is_used_by' && l.omrl == account_omrl} ? e : nil }.reject {|e| e == nil}
      end
    end

    if params[:entity_type] == "flows"
      @entities = Flow.filter(@entities,params)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @entities.to_xml(options) }
    end
  end
  
  # GET /entities/1
  # GET /entities/1.xml
  def show
    if params[:id].to_i == 0
      @entity = Entity.find_by_omrl(params[:id])
    else
      @entity = Entity.find(params[:id],@conditions)
    end

    if @entity
      respond_to do |format|
        options = {:methods => [:omrl]}
        @summaries = get_summaries(@entity,params[:summaries],params[:credentials]) if params.has_key?(:summaries)
        format.html # show.rhtml
        format.xml  do
          xml_str = @entity.to_xml(options) do |xml|
            if @summaries
              @summaries.each do |omrl,summary|
                xml.summary :omrl => omrl,:type => Entity.find_by_omrl(omrl).entity_type do
                  summary.attributes.each {|k,v| xml.tag!(k,v) if k != 'id'}
                end
              end
            end
          end
          render :xml =>  xml_str
        end
      end
    else
      render_status 404            
    end
  end

  # GET /entities/new
  def new
    @entity = Entity.new
  end

  # GET /entities/1;edit
  def edit
    @entity = Entity.find(params[:id])
  end

  # POST /entities
  # POST /entities.xml
  def create
    e = params[:entity].clone
    @entity = Entity.new(e)

    respond_to do |format|
      if @entity.save
        flash[:notice] = 'Entity was successfully created.'
        format.html { redirect_to entity_url(@entity) }
        format.xml  { head :created, :location => entity_url(@entity) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @entity.errors.to_xml }
      end
    end
  end

  # PUT /entities/1
  # PUT /entities/1.xml
  def update
    @entity = Entity.find(params[:id])
    
    if params[:password]  && params[:password] != ''
      @entity.set_credential(params[:tag],params[:password],params[:authorities].split(','))
    end
    if params[:remove_tags] && params[:remove_tags] != ''
      params[:remove_tags].split(',').each { |tag| @entity.remove_credential(tag) }
    end
    if params[:default_auths] && params[:default_auths] != ''
      @entity.set_default_authorities(*params[:default_auths].split(','))
    end
    @entity.attributes = params[:entity]
    respond_to do |format|
      if @entity.save
        flash[:notice] = 'Entity was successfully updated.'
        format.html { redirect_to entity_url(@entity) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @entity.errors.to_xml }
      end
    end
  end

  # DELETE /entities/1
  # DELETE /entities/1.xml
  def destroy
    @entity = Entity.find(params[:id])
    @entity.destroy

    respond_to do |format|
      format.html { redirect_to entities_url }
      format.xml  { head :ok }
    end
  end
  
  private
   
  def check_for_entity_type
    @conditions =  (params[:entity_type]) ? {:conditions => ["entity_type = ? ", params[:entity_type].singularize]} : {}
#    render_text @conditions
  end

  def get_summaries(currency,entity_omrl,credentials,entity_types=nil) #entity_types=['account','currency']
    currency_omrl = currency.omrl
    credential = credentials[currency_omrl] if credentials
    validated = currency.valid_credentials(credential,'view_summaries')
    
#    authenticate_or_request_with_http_basic do |user_name, password|
#      validated = currency.valid_credentials({:tag =>user_name, :password=>password},'view_summaries')
#      raise validated
#    end
    
    if entity_omrl && entity_omrl != ''
      if !validated
        credential = credentials[entity_omrl] if credentials
        entity = Entity.find_by_omrl(entity_omrl)
        validated = entity.valid_credentials(credential,'view_summaries') if entity
      end
      s = SummaryEntry.find(:all,:conditions => ['entity_omrl = ? and currency_omrl = ?',entity_omrl,currency_omrl]) if validated
    else
      s = SummaryEntry.find(:all,:conditions => ['currency_omrl = ?',currency_omrl]) if validated
      s.reject! {|se| !entity_types.include?(Entity.find_by_omrl(se.entity_omrl).entity_type) } if entity_types  
    end
    summaries = {}
    s.each {|x| summaries[x.entity_omrl] = x.summary} if s
    summaries
  end
  
end
