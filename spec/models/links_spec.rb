require File.dirname(__FILE__) + '/../spec_helper'

context "naming links" do
  fixtures :entities
  specify "creating a name link without a name specification should fail" do
    l = Link.new({
      :omrl => entities(:account_mwl).id.to_s,
      :link_type => 'names'
    })
    e = entities(:context_ca)
    (e.links << l).should be_false
  end
  
  specify "creating a name link without a name specification should succeed" do
    l = Link.new({
      :omrl => entities(:account_mwl).id.to_s,
      :link_type => 'names',
      :specification => 'name: mwl'
    })
    e = entities(:context_ca)
    (e.links << l).should == [l]
  end
end

context "find_context_entity_ids" do
  fixtures :entities
  fixtures :links
  specify "should work for top level contexts" do
    Link.find_context_entity_ids('us').should == [entities(:context_us).id]
  end
  specify "should work for multi-level contexts" do
    Link.find_context_entity_ids('ny.us').should == [entities(:context_ny_us).id,entities(:context_us).id]
  end
end


context "fixture" do
  fixtures :entities
  
  specify "we should be able to add a is_used_by link between bucks and zippy" do 
    l = Link.new({
      :omrl => entities(:account_zippy).omrl,
      :link_type => "is_used_by"
    })
    entities(:currency_bucks).links << l
    l.errors.should be_empty
  end

  specify "we should not be able to add a is_used_by link between bucks and us" do 
    l = Link.new({
      :omrl => entities(:context_us).omrl,
      :link_type => "is_used_by"
    })
   lambda{entities(:currency_bucks).links << l}.should raise_error 
  end
end

context "linking entities" do
  fixtures :entities
  
  specify "should only link from context with: names, approves link" do
    from = :context_ca
    { "names"=>:account_mwl,
      "approves"=> :flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should_not raise_error}
    { "is_used_by" => :bucks,
      "declares"=>:flow_tx1,
      "accepts"=>:flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should raise_error}
  end
  
  specify "linking currency to the wrong type of entity should fail" do
    from_omrl = :currency_bucks
    { "names"=>:currency_bucks,
      "names"=>:flow_tx1,
      "names"=>:account_mwl,
      "approves"=>:context_us,
      "approves"=>:currency_bucks,
      "approves"=>:account_mwl,
      "originates_from"=>:context_us,
      "originates_from"=>:currency_bucks,
      "originates_from"=>:flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "should only link from currency with: approves, originates_from, is_used_by link" do
    from = :currency_bucks
    { "approves"=>:flow_tx1,
      "originates_from"=>:account_zippy,
      "is_used_by"=>:account_mwl,
      "is_used_by"=>:account_zippy
      }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should_not raise_error}
    { "accepts"=>:flow_tx1,
      "declares"=>:flow_tx1,
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should raise_error}
  end
  specify "linking currency to the wrong type of entity should fail" do
    from_omrl = :currency_bucks
    { "names"=>:account_mwl,
      "names"=>:currency_bucks,
      "names"=>:flow_tx1,
      "approves"=>:context_us,
      "approves"=>:currency_bucks,
      "approves"=>:account_mwl,
      "originates_from"=>:context_us,
      "originates_from"=>:currency_bucks,
      "originates_from"=>:flow_tx1,
      "is_used_by"=>:context_us,
      "is_used_by"=>:currency_bucks,
      "is_used_by"=>:flow_tx1,
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "should only link from account with: declares, accept link" do
    from_omrl = :account_mwl
    { "declares"=>:flow_tx1,
      "accepts"=>:flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should_not raise_error}
    { "names"=>:context_us,
      "approves"=>:flow_tx1,
      "originates_from"=>:account_mwl,
      "is_used_by"=>:account_mwl
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "linking account to the wrong type of entity should fail" do
    from_omrl = :account_mwl
    { "declares"=>:context_ca,
      "declares"=>:currency_bucks,
      "accepts"=>:context_ca,
      "accepts"=>:currency_bucks
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  specify "should always fail if linking from flow" do
    Link::Types.each { |link_type| lambda {create_link(:flow_tx1,:context_ca,link_type)}.should raise_error  }
  end
      
end

def create_link(from,to,link_type)
  e = entities(from)
  l = Link.new({
    :omrl => (to == nil) ? "" : entities(to).omrl,
    :link_type => link_type
  })
  e.links << l
end
