require File.dirname(__FILE__) + '/../spec_helper'

context "Creating an entity (in general)" do

  specify "should fail for an unknown entity type" do
    lambda {e = Entity.create({
      :entity_type => "bogus_entity_type",
      :specification => <<-eos
        eos
    })}.should raise_error
  end

  specify "should not fail for an known entity type" do
    lambda {e = Entity.create({
      :entity_type => "context",
      :specification => <<-eos
        eos
    })}.should_not raise_error
  end

end

context "fixtures" do
  fixtures :entities
  fixtures :links
  
  specify "entity omrls" do
    entities(:account_zippy).omrl.should == "zippy"
    entities(:context_us).omrl.should == "us"
    entities(:context_ca).omrl.should == "ca"
    entities(:currency_bucks).omrl.should == "bucks"
    entities(:flow_tx1).omrl.should == 'zippy#7'
    entities(:account_mwl).omrl.should == "mwl"
  end
  specify "find_by_omrl should find entities by omrl" do
    Entity.find_by_omrl("mwl").should == entities(:account_mwl)
  end
#  specify "find_by_omrl should not find entities for bad omrl" do
#    Entity.find_by_omrl("xxx").should == nil
#  end

end