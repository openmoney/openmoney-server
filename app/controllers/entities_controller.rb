######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################


# TODO the implementation of the filtering parameters here is totally non-scalable
# gotta figure out how to fix that.

class EntitiesController < ApplicationController

  before_filter :check_for_entity_type
  before_filter :check_for_credentials
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
#      summary_list = check_for_account_summaries
#      options[:summaries] = summary_list
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
      if params[:extra] == 'summary'
        c = @entity.omrl
        e = params[:entity_omrl]
        if e
          s = SummaryEntry.find(:all,:conditions => ['entity_omrl = ? and currency_omrl = ?',e,c])
        else
          s = SummaryEntry.find(:all,:conditions => ['currency_omrl = ?',c])
        end
#        authority = case OMRL.new(e).kind
#        when ACCOUNT
#        when CONTEXT
#          'view_context_summaries'
#        when CURRENCY
#          'view_curency_summary'
#        end
#        @entity.valid_credentials(@credentials,authority)
        
        if s && !s.empty?
          @summaries = {}
          s.each {|x| @summaries[x.entity_omrl] = x.summary}
          respond_to do |format|
            options = {:methods => [:updated_at],:except => [:id]}
            format.html { render :template => 'entities/summary' }
            format.xml  { render :xml => @summaries.to_xml(options) }
          end
        else
          render_status 404            
        end
#          summary_list = check_for_currency_summaries(@entity)
#         summary_list.concat(check_for_account_summaries)
#          options[:summaries] = summary_list
      else
        respond_to do |format|
          options = {:methods => [:omrl]}
          format.html # show.rhtml
          format.xml  { render :xml => @entity.to_xml(options) }
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

  def check_for_credentials
    if params[:credentials]
      params[:credentials] =~ /(.*?)\.(.*)/
      @credentials = {:tag => $1, :password => $2}
    end
  end
 
  def check_for_entity_type
    @conditions =  (params[:entity_type]) ? {:conditions => ["entity_type = ? ", params[:entity_type].singularize]} : {}
#    render_text @conditions
  end
  
  def check_for_account_summaries
    summary_list = []
    params.each do |key,value|
      if key =~/^account_(.*)/
        omrl = $1
        e = Entity.find_by_omrl($1)
        summary_list << omrl if e && e.valid_credentials(:password => value)
      end
    end
    summary_list
  end

  def check_for_currency_summaries(entity)
    summary_list = []
    if entity.valid_credentials(:password => params[:password])
      summary_list << 'count' << 'volume'
    end
  end
end
