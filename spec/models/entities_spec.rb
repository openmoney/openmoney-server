require File.dirname(__FILE__) + '/../spec_helper'

describe "converting to xml" do
  fixtures :entities
  it "should exclude summaries by default" do
    xml = entities(:currency_bucks).to_xml
    xml.should_not =~ /summaries/
  end

  it "should show summaries if specified" do
    xml = entities(:currency_bucks).to_xml(:summaries => ['count','volume','mwl^ca'])
    xml.should =~ /summaries/
    xml.should =~ /mwl\^ca:/
    xml.should_not =~ /zippy\^us:/
  end
end

describe "security" do
  #fixtures :entities
  before(:each) do
    @e = Entity.new
  end
  it "should save password hash and salt to access_control" do
    @e.set_password('fish')
    @e.access_control.should =~ /salt:/
    @e.access_control.should =~ /password_hash:/
  end
  
  it "should approve access when credentials are correct" do
    @e.set_password('fish')
    @e.valid_credentials(:password => 'fish').should be_true
  end

  it "should not approve access when credentials are incorrect" do
    @e.set_password('fish')
    @e.valid_credentials(:password => 'cow').should be_false
  end
  
  it "should approve access when no password was set" do
    @e.valid_credentials(:password => 'fish').should be_true
  end
  
end

describe "Creating an entity (in general)" do

  it "should fail for an unknown entity type" do
    lambda {e = Entity.create({
      :entity_type => "bogus_entity_type",
      :specification => <<-eos
        eos
    })}.should raise_error
  end

  it "should not fail for an known entity type" do
    lambda {e = Entity.create({
      :entity_type => "context",
      :specification => <<-eos
        eos
    })}.should_not raise_error
  end

end

describe "fixtures" do
  fixtures :entities
  fixtures :links

  it "should produce the entities omrls" do
    entities(:account_zippy).omrl.should == "zippy^us."
    entities(:currency_bucks).omrl.should == "bucks~us."
    entities(:flow_tx1).omrl.should == 'zippy#7^us.'
    entities(:account_mwl).omrl.should == "mwl^ca."
    entities(:context_us).omrl.should == "us."
    entities(:context_ca).omrl.should == "ca."
  end
  
  it "find_by_omrl should find unspecified relative omrls" do
    Entity.find_by_omrl("mwl^").should == entities(:account_mwl)
#    Entity.find_by_omrl("zippy#7").should == entities(:flow_tx1)  see TODO below
    Entity.find_by_omrl("bob^").should be_nil
  end

  it "find_by_omrl should find specified relative omrl" do
    Entity.find_by_omrl("mwl^").should == entities(:account_mwl)
    Entity.find_by_omrl("bucks~").should == entities(:currency_bucks)

#    Entity.find_by_omrl("zippy#7^").should == entities(:flow_tx1)
#TODO figure out how/if this should work.  Right now you can't confirm
# the declarer because the declares link is stored as the full omrl (zippy^us.)
# so the relative omrl doesn't match in the search.

    Entity.find_by_omrl("bob^").should be_nil
  end

  it "find_by_omrl should find absolute omrls" do
    Entity.find_by_omrl("mwl^ca").should == entities(:account_mwl)
    Entity.find_by_omrl("bucks~us").should == entities(:currency_bucks)
    Entity.find_by_omrl("zippy#7^us").should == entities(:flow_tx1)
    Entity.find_by_omrl("ca.").should == entities(:context_ca)
#    Entity.find_by_omrl("zippy#7^ca").should be_nil
#TODO this above thing is weird.  If we have code in there to check if this OMRL is actually what it 
# says, then linking in a new flow fails because the check prevents us from finding the flow in the linking
# error checking..  There is a circular problem here that means I haven't thought this all through perfectly yet.

  end

#  specify "find_by_omrl should not find entities for bad omrl" do
#    Entity.find_by_omrl("xxx").should == nil
#  end

end

describe "validation of adding links to entities" do
  
  it "should only be possible to link from a context with: names, approves link" do
    from = 'context'
    { "names"=>'account',
      "approves"=> 'flow'
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should_not raise_error}
    { "is_used_by" => :bucks,
      "declares"=>'flow',
      "accepts"=>'flow'
    }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should raise_error}
  end
  
  it "shouldn't work to link a currency to the wrong type of entity" do
    from_omrl = 'currency'
    { "names"=>'currency',
      "names"=>'flow',
      "names"=>'account',
      "approves"=>'context',
      "approves"=>'currency',
      "approves"=>'account',
      "originates_from"=>'context',
      "originates_from"=>'currency',
      "originates_from"=>'flow',
      "is_used_by"=>'context',
      "is_used_by"=>'currency',
      "is_used_by"=>'flow',
    }.each { |link_type,to_entity| lambda {
      create_link(from_omrl,to_entity,link_type)
      }.should raise_error}
  end

  it "should only link from currency with: approves, originates_from, is_used_by link" do
     from = 'currency'
     { #"approves"=>'flow',  to make this line work we have to supply a real flow in the create link test harness, which we dont!
       "originates_from"=>'account',
       "is_used_by"=>'account'
       }.each { |link_type,to_entity| 
         lambda {create_link(from,to_entity,link_type)}.should_not raise_error}
     { "accepts"=>'flow',
       "declares"=>'flow',
     }.each { |link_type,to_entity| lambda {create_link(from,to_entity,link_type)}.should raise_error}
   end

  it "should only link from account with: declares, accept link" do
    from_omrl = 'account'
    { "declares"=>'flow',
      "accepts"=>'flow'
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should_not raise_error}
    { "names"=>'context',
      "approves"=>'flow',
      "originates_from"=>'account',
      "is_used_by"=>'account'
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  it "should fail to link accounts to the wrong type of entity" do
    from_omrl = 'account'
    { "declares"=>'context',
      "declares"=>'currency',
      "accepts"=>'context',
      "accepts"=>'currency'
    }.each { |link_type,to_entity| lambda {create_link(from_omrl,to_entity,link_type)}.should raise_error}
  end

  it "should always fail if linking from flow" do
    Link::Types.each { |link_type| lambda {create_link('flow','context',link_type)}.should raise_error  }
  end
      
end

def create_link(from,to,link_type)
  e = Entity.create({:entity_type => from})
  if to
    eto = Entity.create({:entity_type => to})
    eto.save
  end
  l = Link.new({
    :omrl => (to == nil) ? "" : eto.url_omrl,
    :link_type => link_type
  })
  l.specification = {'flow'=>'test'}.to_yaml if link_type == 'approves'
  result = e.link_allowed(l)
end