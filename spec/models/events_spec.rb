require File.dirname(__FILE__) + '/../spec_helper'
require 'pp'
module EventSpecHelper
  def valid_attributes
    { :event_type => 'CreateAccount',
      :specification => "some spec"}
  end
end

context "An event (in general)" do
  include EventSpecHelper

  setup do
    @p = Event.new
  end

  specify "should be invalid without an event_type" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :event_type}
    @p.should_not_be_valid
  end

  specify "should be invalid without a specification" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :specification}
    @p.should_not_be_valid
  end

  specify "should be valid with a full set of valid attributes" do
    @p.attributes = valid_attributes
    @p.should_be_valid
  end
end

context "Creating and enmeshing a context event" do
#  fixtures :entities
  setup do
    @root = create_root_context
    
    @e = Event.create({
        :event_type => "CreateContext",
        :specification => <<-eos
parent_context: 1
context_specification: ---
name: ec
eos
      })
    @enmesh_result = @e.enmesh
  end
  
  specify "(root context should be created)" do
    @root.id.should == 1
    @root.errors.full_messages.should == []
  end

  specify "should create a CreateContext event" do
    @e.should be_an_instance_of(Event::CreateContext)
  end

  specify "should succeed" do
    @enmesh_result.should be_true
  end
  
  specify "should produce no errors" do
    @e.errors.full_messages.should == []
  end
  
  specify "should create a context entity" do
    e = Entity.find_entity_by_omrl("ec")
    e.should_not be_nil
    e.entity_type.should == "context"
  end

  specify "which should be available through created_entity" do
    e = Entity.find_entity_by_omrl("ec")
    @e.created_entity.should == e
  end
    
end

context "Given root,ca & us context; mwl.ca & zippy.us accounts joined to bucks currency and tx1 flow in bucks from zippy to mwl, THEN:" do
  fixtures :events

  setup do
    create_root_context
    e = Event.find(:all)
    e.each do |event|
      evt = Event.create({:event_type => event.event_type,:specification => event.specification})
      evt.enmesh
      if e.id == 8
        @tx = evt.created_entity
      end
#      puts "specification: "<<event.specification
      if !evt.errors.empty?
#        puts "ERROR: enmeshing event #{evt.errors.full_messages.join(",")} \n" 
        pp evt
      end
    end
  end

  specify "fixtures should load 8 Events" do
    Event.should have(8).records
  end
  
  specify "canada context should exist and should be a context and be correctly linked" do
    e = Entity.find_entity_by_omrl("ca")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(1).items
    links[0].link_type.should == "names"
    links[0].specification_attribute("name") == "mwl"
  end

  specify "us context should exist and should be a context and be correctly linked" do
    e = Entity.find_entity_by_omrl("us")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(2).items
    links[0].link_type.should == "names"
    links[0].specification_attribute("name").should == "zippy"
    links[1].link_type.should == "names"
    links[1].specification_attribute("name") == "bucks"
  end

  specify "bucks currency should exist and be linked to context, accounts and flow" do
    e = Entity.find_entity_by_omrl("bucks")
    e.should_not be_nil
    e.entity_type.should == "currency"
    links = e.links
#    links.should == ""
    links.should have(4).items
    links[0].link_type.should == "originates_from"
    links[0].omrl.should == "zippy"
    links[1].link_type.should == "is_used_by"
    links[1].omrl.should == "zippy"
    links[2].link_type.should == "is_used_by"
    links[2].omrl.should == "mwl"
    links[3].link_type.should == "approves"
    links[3].omrl.should == "zippy.8"
  end

  specify "ecuador context should not exist" do
    Entity.find_entity_by_omrl("ec").should_be nil
  end

  specify "mwl account should exist and should be an account and linked to flow tx1" do
    e = Entity.find_entity_by_omrl("mwl")
    e.should_not be_nil
    e.entity_type.should == "account"
    links = e.links
    links.should have(1).items
    links[0].omrl.should == "zippy.8"
  end

  specify "tx1 flow should exist and should be a flow and be linked" do
    e = Entity.find_entity_by_omrl("zippy.tx1")
    e.should_not be_nil
    Entity.get_entity_name(e.id).should == e.name
    e.entity_type.should == "flow"
  end
    
  specify "creating a ca context should fail validation (dup)" do
    e = Entity.new({
      :entity_type => "context",
      :specification => <<-eos
        name: ca
        parent_context: 1
        eos
    })
    e.should_not be_valid
  end
  
  specify "creating an ecuador context should be valid" do
    e = Entity.new({
      :entity_type => "context",
      :specification => <<-eos
        name: ec
        parent_context: 1
        eos
    })
    e.should be_valid
  end

  specify "enmeshing a repeat JoinCurrency event should fail" do
    e = Event.create({
      :event_type => "JoinCurrency",
      :specification => <<-eos
        currency: bucks
        account: mwl
  eos
      })
    enmesh_result = e.enmesh
    e.errors.full_messages.should == ["Specification - enmeshing error: duplicate link attempt: bucks already is_used_by mwl"]
    enmesh_result.should be_false
  end

end


def create_root_context
  e = Entity.new({
    :id => 1,
    :entity_type => "context",
    :specification => <<-eos
    eos
  })
  e.id = 1
  e.save
  e
end

