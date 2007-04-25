require File.dirname(__FILE__) + '/../spec_helper'

context "Adding a link" do
  fixtures :entities

  specify "should not happen if the entity denies (unknown link_type)" do
    e = Entity.find_named_entity("tx1")
    puts e.entity_type
    l = Link.new({
      :link_type => "approves",
      :omrl => "tx1"   
    })
    lambda {(e.links << l)}.should raise_error
  end

  specify "should happen if the entity allows it" do
    e = Entity.find_named_entity("ca")
    puts e.entity_type
    l = Link.new({
      :link_type => "approves",
      :omrl => "tx1"   
    })
    lambda {(e.links << l)}.should_not raise_error
  end

end