class Event < ActiveRecord::Base

  include Specification
  
  # this is a factory that creates Events of the correct type if they have been
  # subclassed, otherwise it raises an exception
  def self.create(params)
    class_name = "Event::#{params[:event_type]}"
    begin
      class_name.constantize.new(params)
    rescue
      raise "Unknown event type: #{params[:event_type]}"
    end
  end
  
  def enmesh(validations,attribute_name = :specification)
    validate_specification(validations,attribute_name)
    if errors.empty? 
      errs = []
      yield errs
      errors.add(attribute_name, "- enmeshing error: " << errs.join(",")) if !errs.empty?
    end
    errors.empty?
  end
  
  class CreateEvent < Event
    def enmesh(entity_type,validations)
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
    
    def enmesh_parent_omrl(entity_type)
      enmesh(entity_type,{'specification' => :required, 'parent_omrl' => :required}) {|entity| create_link(@specification['parent_omrl'],entity.omrl,'named_in')}
    end
  end

  class CreateContext < CreateEvent
    def enmesh
      enmesh_parent_omrl 'context'
    end
  end

  class CreateCurrency < CreateEvent
    def enmesh
      enmesh_parent_omrl 'currency'
    end
  end

  class CreateAccount < CreateEvent
    def enmesh
      enmesh_parent_omrl 'account'
    end
  end

  class JoinCurrency < Event
    def enmesh
      super({'account_omrl' => :required, 'currency_omrl' => :required}) do |errs|
        begin
          create_link(@specification['currency_omrl'],@specification['account_omrl'],'uses')
        rescue Exception => e
          errs  << e.to_s
        end
      end
    end
  end

  class AcknowledgeFlow < CreateEvent
    def enmesh
      super('flow',{'specification' => :required,'from_account_omrl' => :required,'to_account_omrl' => :required,'currency_omrl' => :required}) do |entity|
        links = []
        begin
          entity_omrl = entity.omrl
          { 'from_account_omrl'=>'flow_from',
            'to_account_omrl'=>'flow_to',
            'currency_omrl'=>'approves',
            }.each {|from_omrl,link_type| links << create_link(@specification[from_omrl],entity_omrl,link_type)}
        rescue Exception => e
          links.each |link| link.destroy
          raise e
        end
        
      end
    end
  end

  def create_link(from_omrl,to_omrl,link_type)
    link_params = {:link_type => link_type,:omrl => to_omrl}
    omrl = OMRL.new(from_omrl)
    from_entity = omrl.local?
    if (from_entity) 
      link = Link.new(link_params)
      unless from_entity.links << link
        raise "couldn't create the link!"
      end
      link
    else
      Post.new(omrl.url << '/links',link_params)
    end
  end

end

