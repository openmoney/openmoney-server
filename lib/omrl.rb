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


class OMRL
  OM_NUM = :num
  OM_NAME = :name
  OM_URL = :url

  attr_reader :omrl

  ######################################################################################
  def initialize(o = '')
    @omrl = o.to_s  #since a plain number is a valid omrl we always covert all input to a string
    @type = nil
    @url = nil
    @num = nil
    @name = nil
    @local = nil
  end
  
  ######################################################################################
  def omrl=(o)
    #if we set the omrl we have to clear the cached values
    initialze(o)
  end
  
  ######################################################################################
  #returns the type as one of the constants :om_num, :url or :om_name
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
  
  ######################################################################################
  #does this omrl exist on this server?
  def local?
    return @local if @local != nil
    
    u = URI.parse(url)
    if u.relative?
      id = num
    else
      raise "local? for non relative urls not implemented"
      # figure out if the non-relative url is local
    end
    if (id == 0) 
      @local = false
    else
      begin
        e = Entity.find(id)
        @local = e
      rescue ActiveRecord::RecordNotFound
        @local = false
      end
    end
  end
  
  ######################################################################################
  #  return the URL for this omrl by resolving it
  def url
    return @url if @url != nil #return cached value
    @url = resolve_to_url()
  end

  ######################################################################################
  def num
    return @num if @num != nil #return cached value
    case type
    when OM_URL
      #TODO: is this right?  The num is just the id at the right hand of the URL?  
      if @omrl =~/([0-9]+)$/
        @num = $1
      else
        raise "unable to convert a URL omrl to an OM_NUM [for omrl #{@omrl}]"
      end
    when OM_NUM
      @num = @omrl
    when OM_NAME
      @num = resolve_name_to_num(@omrl)
    end
  end
  ######################################################################################
  def name
    return @name if @name != nil #return cached value
    case type
    when OM_URL, OM_NUM
      @name = Link.find_entity_name(num)
    when OM_NAME
      @name = @omrl
    end
  end

  private
  
  ######################################################################################
  #resolves the omrl down to a url 
  def resolve_to_url()
    case type
    when OM_URL
      @omrl
    when OM_NUM
      resolve_num_to_url(@omrl)
    when OM_NAME
      resolve_num_to_url(num)
    end
  end
  
  ######################################################################################
  def resolve_num_to_url(om_num)
    return "/entities/#{om_num}" if om_num =~ /^\d+$/
    raise "resolve_num_to_url not implemented for external om nums! [omrl #{@omrl} = num #{om_num}]"
  end
  
  ######################################################################################
  def resolve_name_to_num(om_name)
    if om_name == ''
      return "1"
    end
    if om_name =~ /#(.*)/
      return $1
    end
    l = Link.find_naming_link(om_name)
    if l
      l.omrl  #TODO: this works because a naming link must allways use a OMRL_NUM?????
    else
      raise "resolve_name_to_num not implemented for non local omrl #{@omrl} name=#{om_name}"
    end
  end
end
