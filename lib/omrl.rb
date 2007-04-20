######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

# OMRL = open money resource locator.
# an omrl can be any of three things: 
#   1- an open money name like zippy^cc.ny.us or bucks~vegetarians.us
#   2- an open money number like 1^2233.12.1 or 76~3334321.1
#   3- a transport url like: http://openmoney.info/entities/1 (or a relative one like this: /entities/1)
# additionally omrls can be absolute or relative.  i.e. a relative open money number is just a number (i.e. an id)
# and a relative openmoney name is just text followed by ~ or ^ to distinguish between accounts and currencies

OM_NUM = :num
OM_NAME = :name
OM_URL = :url

class OMRL
  attr_reader :omrl
  def initialize(o = '')
    @omrl = o.to_s  #since a plain number is a valid omrl we always covert all input to a string
  end
  
  def omrl=(o)
    @type = nil #if we set the omrl we have to clear the cached values
    @url = nil
    @entity = nil
    @omrl = o
  end
  
  #returns the type as a symbol :om_num, :url or :om_name
  def type
    return @type if @type != nil #return cached value
    @type = case @omrl
    when /^[0-9][0-9.]*[0-9]*/
      OM_NUM
    when /^(\w+:)|\//
      OM_URL
    else
      OM_NAME
    end
  end
  
  #does this omrl exist on this server?
  def local?
    if (@local) 
      @local[:entity]
    else
      @local = {}
      u = URI.parse(url)
      if u.relative?
        id = num
      else
        # figure out if the non-relative url is local
      end
      e = Entity.find(id) if id != 0
      @local[:entity] = e
    end
  end
  
  #  return the URL for this omrl by resolving it
  def url
    return @url if @url != nil #return cached value
    @url = resolve_to_url
  end

  def num
    return @num if @num != nil #return cached value
    case type
    when OM_URL
      raise "unable to convert a URL omrl to an OM_NAME [for omrl #{@omrl}]"
    when OM_NUM
      @omrl
    when OM_NAME
      @num = resolve_name_to_num
    end
  end
  
  private
  
  #resolves the omrl down to a url 
  def resolve_to_url()
    case type
    when OM_URL
      @omrl
    when OM_NUM
      resolve_num_to_url(@omrl)
    when OM_NAME
      resolve_num_to_url(num(@omrl))
    end
  end
  
  def resolve_num_to_url(om_num)
    return '' if @omrl == ''
    return "/entities/#@omrl" if @omrl =~ /^\d+$/
    raise "resolve_num_to_url not implemented for external om nums! [omrl #{@omrl}]"
  end
  
  def resolve_name_to_num(om_num)
    return '' if @omrl == ''
    raise "resolve_name_to_num not implemented! for omrl #{@omrl}"
  end
end
