require File.dirname(__FILE__) + '/../spec_helper'

context "linking entities" do
  fixtures :entities
  
  setup do
    @link_types = %W(named_in approves created_by managed_by flow_to flow_from)
  end

  specify "should only link from context with: named_id, approves, created_by, managed_by link" do
    from_omrl = "ca"
    { "named_in"=>"root",
      "approves"=>"tx1",
      "created_by"=>"mwl",
      "managed_by"=>"zippy"
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should_not raise_error}
    { "uses" => "bucks",
      "flow_to"=>"tx1",
      "flow_from"=>"tx1",
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end
  specify "linking context to the wrong type of entity should fail" do
    from_omrl = "bucks"
    { "named_in"=>"bucks",
      "named_in"=>"tx1",
      "named_in"=>"mwl",
      "approves"=>"us",
      "approves"=>"bucks",
      "approves"=>"mwl",
      "created_by"=>"us",
      "created_by"=>"bucks",
      "created_by"=>"tx1",
      "managed_by"=>"us",
      "managed_by"=>"bucks",
      "managed_by"=>"tx1",
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "should only link from currency with: named_id, approves, created_by, managed_by, uses link" do
    from_omrl = "bucks"
    { "named_in"=>"us",
      "approves"=>"tx1",
      "created_by"=>"mwl",
      "managed_by"=>"zippy",
      "uses"=>"account"
      }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should_not raise_error}
    { "flow_to"=>"tx1",
      "flow_from"=>"tx1",
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end
  specify "linking currency to the wrong type of entity should fail" do
    from_omrl = "bucks"
    { "named_in"=>"mwl",
      "named_in"=>"bucks",
      "named_in"=>"tx1",
      "approves"=>"us",
      "approves"=>"bucks",
      "approves"=>"mwl",
      "created_by"=>"us",
      "created_by"=>"bucks",
      "created_by"=>"tx1",
      "managed_by"=>"us",
      "managed_by"=>"bucks",
      "managed_by"=>"tx1",
      "uses"=>"us",
      "uses"=>"bucks",
      "uses"=>"tx1",
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "should only link from account with: flow_to, flow_from link" do
    from_omrl = "mwl"
    { "flow_from"=>"tx1",
      "flow_to"=>"tx1"
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should_not raise_error}
    { "named_in"=>"us",
      "approves"=>"tx1",
      "created_by"=>"mwl",
      "managed_by"=>"zippy",
      "uses"=>"account"
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "linking account to the wrong type of entity should fail" do
    from_omrl = "mwl"
    { "flow_from"=>"ca",
      "flow_from"=>"bucks",
      "flow_to"=>"ca"
      "flow_to"=>"bucks"
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
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
