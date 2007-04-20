######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

# a class to wrap posting to a web-site

class Post
  attr_reader :result

  def initialize (url,params)
    uri = URI.parse(url.to_s)
#    uri.scheme ||= 'http'
 #   uri.host ||= 'localhost'
  #  uri.port ||= 3000
    
    req = Net::HTTP::Post.new(uri.path)
#    req.basic_auth 'jack', 'pass'
    req.set_form_data(params)
    res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      @result = res.body
    else
      res.error!
    end
  end
end

