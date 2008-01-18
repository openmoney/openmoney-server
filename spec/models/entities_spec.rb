require File.dirname(__FILE__) + '/../spec_helper'

describe "converting to xml" do
  fixtures :entities
  it "should exclude summaries by default" do
    xml = entities(:currency_bucks).to_xml
    xml.should_not =~ /summaries/
  end

  it "should show summaries if specified" do
    xml = entities(:currency_bucks).to_xml(:summaries => ['count','volume','mwl.ca'])
    xml.should =~ /summaries/
    xml.should =~ /mwl.ca:/
    xml.should_not =~ /zippy.us:/
  end
end

describe "security" do
  #fixtures :entities
  before(:each) do
    @e = Entity.new
  end
  it "should save a credential record with password hash and salt to access_control" do
    @e.set_credential('eric','fish',['declares'])
    ac = YAML.load(@e.access_control) 
    ac.has_key?('eric').should be_true
    ac['eric'].has_key?(:salt).should be_true
    ac['eric'].has_key?(:password_hash).should be_true
    ac['eric'].has_key?(:authorities).should be_true
  end
  
  it "should approve access when credentials are correct" do
    @e.set_credential('eric','fish',['declares'])
    @e.valid_credentials({:tag=>'eric',:password => 'fish'},'declares').should be_true
    @e.valid_credentials({:tag=>'eric',:password => 'fish'},'approves').should be_false
  end

  it "should approve access when for wildcard authority credentials" do
    @e.set_credential('eric','fish','*')
    @e.valid_credentials({:tag=>'eric',:password => 'fish'},'declares').should be_true
    @e.valid_credentials({:tag=>'eric',:password => 'fish'},'approves').should be_true
  end

  it "should not approve access when credentials are incorrect" do
    @e.set_credential('eric','fish',['declares'])
    @e.valid_credentials({:tag=>'eric',:password => 'cow'},'declares').should be_false
    @e.valid_credentials({:tag=>'joe',:password => 'fish'},'declares').should be_false
    @e.valid_credentials({:tag=>'joe',:password => 'fish'},'approves').should be_false
  end
  
  it "should approve access when no credentials were set" do
    @e.valid_credentials({:tag=>'eric',:password => 'cow'},'declares').should be_true
    @e.valid_credentials(nil,'declares').should be_true
  end

  it "should set default authorities" do
    @e.default_authorities.should == []
    @e.set_default_authorities('accepts')
    @e.default_authorities.should == ['accepts']
  end
  
  it "should approve access when default authorities were set" do
    @e.set_default_authorities('accepts')
    @e.valid_credentials({:tag=>'eric',:password => 'cow'},'accepts').should be_true
    @e.valid_credentials(nil,'accepts').should be_true
    @e.valid_credentials({:tag=>'eric',:password => 'cow'},'declares').should be_false
    @e.valid_credentials(nil,'declares').should be_false
  end
  
  it "should be able to clear a credential" do
    @e.set_credential('eric','fish',['declares'])
    @e.set_credential('joe','cow',['approves'])
    ac = YAML.load(@e.access_control) 
    ac.has_key?('joe').should be_true
    ac.has_key?('eric').should be_true
    @e.remove_credential('joe')
    ac = YAML.load(@e.access_control) 
    ac.has_key?('joe').should be_false
    ac.has_key?('eric').should be_true
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
    entities(:account_zippy).omrl.should == "zippy.us"
    entities(:currency_bucks).omrl.should == "bucks.us"
    entities(:flow_tx1).omrl.should == 'zippy.us/7'
    entities(:account_mwl).omrl.should == "mwl.ca"
    entities(:context_us).omrl.should == "us"
    entities(:context_ca).omrl.should == "ca"
  end


  it "find_by_omrl should find omrls" do
    Entity.find_by_omrl("mwl.ca").should == entities(:account_mwl)
    Entity.find_by_omrl("bucks.us").should == entities(:currency_bucks)
    Entity.find_by_omrl("zippy.us/7").should == entities(:flow_tx1)
    Entity.find_by_omrl("ca").should == entities(:context_ca)
    Entity.find_by_omrl("bob").should be_nil
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
      "is_used_by"=>'context',
      "is_used_by"=>'currency',
      "is_used_by"=>'flow',
    }.each { |link_type,to_entity| lambda {
      create_link(from_omrl,to_entity,link_type)
      }.should raise_error}
  end

  it "should only link from currency with: approves, and is_used_by link" do
     from = 'currency'
     { #"approves"=>'flow',  to make this line work we have to supply a real flow in the create link test harness, which we dont!
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
    :omrl => (to == nil) ? "" : eto.url,
    :link_type => link_type
  })
  l.specification = {'flow'=>'test'}.to_yaml if link_type == 'approves'
  result = e.link_allowed(l)
end