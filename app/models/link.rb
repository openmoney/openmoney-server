######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Link < ActiveRecord::Base
  include Specification

  Types = %w(names approves originates_from accepts declares is_used_by)

  belongs_to :entity
  validates_inclusion_of :link_type, :in => Types
  validates_presence_of :omrl
  validates_presence_of :entity_id

  def initialize(params)
    super(params)
  end

  ######################################################################################
  def validate_on_create
    case link_type
    when 'names'
      validate_specification({'name' => :required})
      if @specification
        n = @specification['name']
        if Link.find_naming_link(n,entity_id.to_i)
          errors.add(:specification,"name '#{n}' already exists")
        end
      end
    end
    false
  end

  def omrl_url
    o = OMRL.new(omrl)
    o.url
  end
  
  ######################################################################################
  # CLASS METHODS
  ######################################################################################

  # class method to return a naming link optionally from a given context
  def Link.find_naming_link(name,context=nil)

    if (context) 
      if context.is_a? Integer
        entity_id = context
      else
        entity_id = Link.find_context_entity_ids(context)[0]
      end
      conditions = ["link_type = 'names' and entity_id = ? and specification like ?", entity_id,"%name: #{name}%"]
    else
      conditions = ["link_type = 'names' and specification like ?", "%name: #{name}%"]
    end
    links = Link.find(:all, :conditions => conditions)
    return nil if links.size == 0
    return links[0] if links.size == 1
    links
  end

  ######################################################################################
  # given a context, return a list of the context entity ids while verifying that the
  # links actually exist.
  def Link.find_context_entity_ids(context='')
    entity_id = 1
    contexts = []
    if context == ''
      contexts.push(1)
    else
      hierarchy = context.split(/\./).reverse
      #TODO this is brutally slow, but it should work.
      for name in hierarchy do 
        l = Link.find(:first,:conditions => ["link_type = 'names' and entity_id = ? and specification like ?", entity_id,"%name: #{name}%"])
        raise "link not found to #{name} from #{entity_id}" if !l
        o = OMRL.new(l.omrl)
        #TODO these exceptions need to be refactored and rationalized.
        raise "HMMM.. A naming link omrl (#{l.omrl}) must be a OM_NUM omrl (was #{o.type.to_s})" if !o.om_num?
        raise "HMMM.. expected the the naming link omrl (#{l.omrl}) to be a context but it wasn't (was #{o.kind.to_s})" if !o.context?
        entity_id = o.context.to_i
        contexts.unshift(entity_id)
      end
    end
    contexts
  end
  
  ######################################################################################
  def Link.find_declaring_entity(num)
    conditions = ["link_type = 'declares' and omrl = ?", num]
    link = Link.find(:first, :conditions => conditions)
    link.entity if link
  end
  
  ######################################################################################
  def Link.find_entity_name(num)
    conditions = ["link_type = 'names' and omrl = ?", num]
    link = Link.find(:first, :conditions => conditions)
    #TODO handles only the first naming link!!
    return link.specification_attribute("name") if link
    nil
  end

end
