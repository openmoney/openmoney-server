require File.dirname(__FILE__) + '/../spec_helper'

describe "creating naming links" do
  fixtures :entities
  fixtures :links

  # delete this one item from the fixtures because we are testing adding it back in
  before(:each) do
    Link.destroy(links(:names_account_mwl_in_ca).id)
  end
  
  it "shouldn't work to create a name link without a name specification" do
    l = Link.new({
      :omrl => "/entities/" << entities(:account_mwl).id.to_s,
      :link_type => 'names'
    })
    e = entities(:context_ca)
    (e.links << l).should be_false
  end
  
  it "should work to create a name ling if the specification is complete" do
    l = Link.new({
      :omrl => "/entities/" << entities(:account_mwl).id.to_s,
      :link_type => 'names',
      :specification => 'name: mwl'
    })
    e = entities(:context_ca)
    (e.links << l).should == [l]
  end
end

describe "creating is_used_by links" do
  fixtures :entities
  fixtures :links
  it "should work to add a is_used_by link between an account and a currency but not if it's allready linked" do 
    l = Link.new({
      :omrl => entities(:account_zippy).omrl,
      :link_type => "is_used_by"
    })
    entities(:currency_bucks).links << l
    l.errors.full_messages.should == []
    
    lambda{entities(:currency_bucks).links << l}.should raise_error     
  end

  it "shouldn't work to add a is_used_by link between a currency an a context" do 
    l = Link.new({
      :omrl => entities(:context_us).omrl,
      :link_type => "is_used_by"
    })
   lambda{entities(:currency_bucks).links << l}.should raise_error 
  end
end
describe "searching for naming links" do
  fixtures :entities
  fixtures :links

  it "should find links for contexts" do
    Link.find_naming_link('ca').should == links(:names_context_ca_in_root)
  end
  it "should find links for accounts" do
    Link.find_naming_link('mwl').should == links(:names_account_mwl_in_ca)
  end
  it "should find an array of links for ambiguous name" do
    Link.find_naming_link('zippy').should == [links(:names_account_zippy_in_us),links(:names_account_zippyny_ny_us)]
  end
  it "should return nil for non existent names" do
    Link.find_naming_link('zaphrod').should be_nil
  end
  it "should find links when contexts are specified as Entity objects" do
    Link.find_naming_link("ny", entities(:context_us)).should == links(:names_context_ny_in_us)
  end
  it "should find links when contexts are specified as strings" do
    Link.find_naming_link('zippy','ny.us').should == links(:names_account_zippyny_ny_us)
  end
  it "should find links when contexts are specified entity ids" do
    Link.find_naming_link('zippy',entities(:context_us).id).should == links(:names_account_zippy_in_us)
  end
  it "should return nil for names not in a context" do
    Link.find_naming_link('zippy',entities(:context_ca)).should be_nil
  end
  
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
    omrl = entities(:flow_tx1).omrl
    fake_flow_omrl = OMRL.new_flow(OMRL.new(omrl).flow_declarer,33).to_s
    Link.find_declaring_entity(fake_flow_omrl).should == nil
  end
end

