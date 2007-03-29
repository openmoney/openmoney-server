class Link < ActiveRecord::Base
  belongs_to :entity
  
  def omrl_url
    o = OMRL.new(omrl)
    o.url
  end
end
