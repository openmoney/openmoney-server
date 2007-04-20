######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Link < ActiveRecord::Base
  belongs_to :entity
  
  def omrl_url
    o = OMRL.new(omrl)
    o.url
  end
end
