######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class EventsController < ApplicationController
  # GET /events
  # GET /events.xml
  def index
    @events = Event.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @events.to_xml }
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @event.to_xml }
    end
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1;edit
  def edit
    @event = Event.find(params[:id])
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.create(params[:event])
    respond_to do |format|
      # TODO: need to add something here to make enmeshment unwind if the event.save fails.
      # perhaps even merging the two
      if @event.errors.empty? && (result = @event.enmesh)
        @event.result = result
        if true #TODO this is failing on a join currency post from rubycc @event.save
          flash[:notice] = 'Event caused some churn.'
          format.html { redirect_to event_url(@event) }
          format.xml  { render :xml => {'result' => result.to_yaml}.to_xml,:status => :created, :location => event_url(@event) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @event.errors.to_xml }
        end
      else
        logger.info "RESULT" << @event.errors.full_messages.inspect
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])
        flash[:notice] = 'Event was successfully updated.'
        format.html { redirect_to event_url(@event) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors.to_xml }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.xml  { head :ok }
    end
  end
end
