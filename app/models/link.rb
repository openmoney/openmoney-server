######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Link < ActiveRecord::Base

  Types = %w(named_in approves created_by managed_by flow_to flow_from uses)

  belongs_to :entity
  validates_inclusion_of :link_type, :in => Types
  
  def omrl_url
    o = OMRL.new(omrl)
    o.url
  end
  
  def link_to_entity
    #TODO this will fail for non-local link_to omrls
    @link_to_entity ||= Entity.find_entity_by_omrl(omrl)
  end
end
