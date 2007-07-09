require File.dirname(__FILE__) + '/../spec_helper'

describe "naming links" do
  fixtures :entities
  it "creating a name link without a name specification should fail" do
    l = Link.new({
      :omrl => "/entities/" << entities(:account_mwl).id.to_s,
      :link_type => 'names'
    })
    e = entities(:context_ca)
    (e.links << l).should be_false
  end
  
  it "creating a name link with a name specification should succeed" do
    l = Link.new({
      :omrl => "/entities/" << entities(:account_mwl).id.to_s,
      :link_type => 'names',
      :specification => 'name: mwl'
    })
    e = entities(:context_ca)
    (e.links << l).should == [l]
  end
end


describe "fixtures " do
  fixtures :entities
  
  it "we should be able to add a is_used_by link between bucks and zippy" do 
    l = Link.new({
      :omrl => entities(:account_zippy).omrl,
      :link_type => "is_used_by"
    })
    entities(:currency_bucks).links << l
    l.errors.should be_empty
  end

  it "we should not be able to add a is_used_by link between bucks and us" do 
    l = Link.new({
      :omrl => entities(:context_us).omrl,
      :link_type => "is_used_by"
    })
   lambda{entities(:currency_bucks).links << l}.should raise_error 
  end
end

describe "linking entities" do
  fixtures :entities
  
  it "should only link from context with: names, approves link" do
    from = :context_ca
    { "names"=>:account_mwl,
      "approves"=> :flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should_not raise_error}
    { "is_used_by" => :bucks,
      "declares"=>:flow_tx1,
      "accepts"=>:flow_tx1
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should raise_error}
  end
  
  it "linking currency to the wrong type of entity should fail" do
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

  it "should only link from currency with: approves, originates_from, is_used_by link" do
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
  it "linking currency to the wrong type of entity should fail" do
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

  it "should only link from account with: declares, accept link" do
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

  it "linking account to the wrong type of entity should fail" do
    from_omrl = :account_mwl
    { "declares"=>:context_ca,
      "declares"=>:currency_bucks,
      "accepts"=>:context_ca,
      "accepts"=>:currency_bucks
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  it "should always fail if linking from flow" do
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


describe "searching for naming chain of entites linked by 'names'" do
  fixtures :entities
  fixtures :links

  it "should find root context" do
    Link.entity_naming_chain(entities(:context_root).id).should == []
  end

  it "should find names of context entities" do
    Link.entity_naming_chain(entities(:context_ca).id).should == ["ca"]
  end
  
  it "should find contexts of account entities" do
    Link.entity_naming_chain(entities(:account_zippy).id).should == ["zippy","us"]
  end
end

describe "searching for entities linked by 'declares'" do
  fixtures :entities
  fixtures :links
  it "should find flows that exist" do
    Link.find_declaring_entity(entities(:flow_tx1).omrl).should == entities(:account_zippy)
  end
  
  it "should not find flows that dont exist" do
    fake_flow_omrl = OMRL.new(entities(:flow_tx1).omrl).entity << ".ca"
    Link.find_declaring_entity(fake_flow_omrl).should == nil
  end
end

