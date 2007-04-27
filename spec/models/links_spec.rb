require File.dirname(__FILE__) + '/../spec_helper'

context "linking entities" do
  fixtures :entities
  
  setup do
    @link_types = %W(named_id approves created_by managed_by flow_to flow_from)
  end

  specify "should only link from context with: named_id, approves, created_by, managed_by link" do
    { "named_in"=>"root",
      "approves"=>"tx1",
      "created_by"=>"mwl",
      "managed_by"=>"zippy"
      }.each { |link_type,to_entity| lambda {create_link("ca",to_entity,link_type)}.should_not raise_error}
  end

  specify "should only link from currency with: named_id, approves, created_by, managed_by, uses link" do
    { "named_in"=>"us",
      "approves"=>"tx1",
      "created_by"=>"mwl",
      "managed_by"=>"zippy",
      "uses"=>"account"
      }.each { |link_type,to_entity| lambda {create_link("bucks",to_entity,link_type)}.should_not raise_error}
  end

  specify "should only link from account with: flow_to, flow_from link" do
    { "flow_from"=>"tx1",
      "flow_to"=>"tx1"
      }.each { |link_type,to_entity| lambda {create_link("mwl",to_entity,link_type)}.should_not raise_error}
  end

  specify "should always fail if linking from flow" do
    @link_types.each { |link_type| lambda {create_link("tx1","ca",link_type)}.should raise_error  }
  end
    
end

def create_link(from_omrl,to_omrl,link_type)
  e = Entity.find_named_entity(from_omrl)
  l = Link.new({
    :omrl => to_omrl,
    :link_type => link_type
  })
  e.links << l
end
