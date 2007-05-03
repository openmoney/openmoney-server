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

  ######################################################################################
  def validate_on_create
    case link_type
    when 'names'
      validate_specification({'name' => :required})
      if @specification
        n = @specification['name']
        if Link.find_name_link(n,entity_id)
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
  # class method to return a naming link optionally of from a given entity
  def Link.find_name_link(name,entity_id=nil)
    if (entity_id) 
      conditions = ["link_type = 'names' and entity_id = ? and specification like ?", entity_id,"%name: #{name}%"]
    else
      conditions = ["link_type = 'names' and specification like ?", "%name: #{name}%"]
    end
    Link.find(:first, :conditions => conditions)
  end


end
