######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
#
######################################################################################
# Events are what happens to create the mesh that is the relationships of linked
# entities.
# The Event class is subclassed for each event type.
# Each event type must either pass a block to or override the enmesh method to implement
# what the event consists of, which is usually either the creation of a new entity, and
# or linking together of existing entities by creating new link objects.

class Event < ActiveRecord::Base
  validates_presence_of :event_type
  validates_presence_of :specification
  
  include Specification
  
  ######################################################################################
  # this is a factory method that creates Events of the correct type if they have been
  # subclassed, otherwise it raises an exception
  def self.create(params)
    class_name = "Event::#{params[:event_type]}"
    begin
      class_name.constantize.new(params)
    rescue
      raise "Unknown event type: #{params[:event_type]}"
    end
  end
  
  ######################################################################################
  # the abstract act of enmeshing is simply to validate the specification of the event
  # and then (if it's valid) to yeild to the block which which can add further errors
  # if it wants.
  def _enmesh(validations,attribute_name = :specification)
    validate_specification(validations,attribute_name)
    if errors.empty? 
      errs = []
      yield errs
      errors.add(attribute_name, "- enmeshing error: " << errs.join(",")) if !errs.empty?
    end
    errors.empty?
  end

  ######################################################################################
  # some events are entity creation events.  CreateEvent is a base class for all such events
  # it over-rides enmesh, accepting the entity type to be created, and defines a block
  # with which it calls the super-class "enmesh" method that actually does the creation of
  # the entity record.  If the creation of the entity is succesfull it in turns yields
  # to the callers block which can do something with the created entity.
  class CreateEvent < Event
    def _enmesh(entity_type,validations)
      validations ||= {'specification' => :required}
      super(validations) do |errs|
        entity = Entity.new({:entity_type => entity_type,:specification => @specification['specification'].to_yaml})
        if (!entity.save)
          errs << "Error#{(entity.errors.count>1)? 's' : ''} creating entity: #{entity.errors.full_messages.join(',')}"
        else
          begin
            yield entity
          rescue Exception => e
            errs  << e.to_s
            entity.destroy
          end
        end
      end
    end
    
    ######################################################################################
    # Some entities when created must have a parent entity.  This method can be used by
    # any subclasses of Create event.  It sets up the standard validation for the specification
    # to include the parent entities omrl.  It also implements the block which
    # links the new entity to the parent entity
    def enmesh_parent_omrl(entity_type)
      _enmesh(entity_type,{'specification' => :required, 'parent_omrl' => :required}) {|entity| create_link(@specification['parent_omrl'],entity.omrl,'named_in')}
    end
  end

  ######################################################################################
  class CreateContext < CreateEvent
    def enmesh
      enmesh_parent_omrl 'context'
    end
  end

  ######################################################################################
  class CreateCurrency < CreateEvent
    def enmesh
      enmesh_parent_omrl 'currency'
    end
  end

  ######################################################################################
  class CreateAccount < CreateEvent
    def enmesh
      enmesh_parent_omrl 'account'
    end
  end

  ######################################################################################
  class JoinCurrency < Event
    def enmesh
      _enmesh({'account_omrl' => :required, 'currency_omrl' => :required}) do |errs|
        begin
          create_link(@specification['currency_omrl'],@specification['account_omrl'],'uses')
        rescue Exception => e
          errs  << e.to_s
        end
      end
    end
  end

  ######################################################################################
  class AcknowledgeFlow < CreateEvent
    def enmesh
      _enmesh('flow',{'specification' => :required,'from_account_omrl' => :required,'to_account_omrl' => :required,'currency_omrl' => :required}) do |entity|
        links = []
        begin
          entity_omrl = entity.omrl
          { 'from_account_omrl'=>'flow_from',
            'to_account_omrl'=>'flow_to',
            'currency_omrl'=>'approves',
            }.each {|from_omrl,link_type| links << create_link(@specification[from_omrl],entity_omrl,link_type)}
        rescue Exception => e
          links.each {|link| link.destroy}
          raise e
        end
        
      end
    end
  end

protected
  ######################################################################################
  # 
  def create_link(from_omrl,to_omrl,link_type)
    link_params = {:link_type => link_type,:omrl => to_omrl}
    omrl = OMRL.new(from_omrl)
    from_entity = omrl.local?
    if (from_entity) 
      link = Link.new(link_params)
      unless from_entity.links << link
        raise "couldn't create the link! #{link.errors.full_messages.join(',')}"
      end
      link
    else
      raise "#{omrl.url} not local"
      Post.new(omrl.url << '/links',link_params)
    end
  end

end

