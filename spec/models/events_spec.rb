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
    create_root_context
    
    @e = Event.create({
        :event_type => "CreateContext",
        :specification => <<-eos
parent_omrl: root
specification: 
  name: ec
eos
      })
    @enmesh_result = @e.enmesh
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
    e = Entity.find_named_entity("ec")
    e.should_not be_nil
    e.entity_type.should == "context"
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
#      puts "specification: "<<event.specification
      if !evt.errors.empty?
        puts "ERROR: enmeshing event #{evt.errors.full_messages.join(",")} \n" 
        pp evt
      end
    end
  end

  specify "fixtures should load 8 Events" do
    Event.should have(8).records
  end
  
  specify "canada context should exist and should be a context and be correctly linked" do
    e = Entity.find_named_entity("ca")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(1).items
    links[0].link_type.should == "named_in"
    links[0].omrl.should == "mwl"
  end

  specify "us context should exist and should be a context and be correctly linked" do
    e = Entity.find_named_entity("us")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(2).items
    links[0].link_type.should == "named_in"
    links[0].omrl.should == "zippy"
    links[1].link_type.should == "named_in"
    links[1].omrl.should == "bucks"
  end

  specify "bucks currency should exist and be linked to context, accounts and flow" do
    e = Entity.find_named_entity("bucks")
    e.should_not be_nil
    e.entity_type.should == "currency"
    links = e.links
#    links.should == ""
    links.should have(3).items
    links[0].link_type.should == "uses"
    links[0].omrl.should == "zippy"
    links[1].link_type.should == "uses"
    links[1].omrl.should == "mwl"
    links[2].link_type.should == "approves"
    links[2].omrl.should == "tx1"
  end

  specify "ecuador context should not exist" do
    Entity.find_named_entity("ec").should_be nil
  end

  specify "mwl account should exist and should be an account and linked to flow tx1" do
    e = Entity.find_named_entity("mwl")
    e.should_not be_nil
    e.entity_type.should == "account"
    e.name.should == "mwl"
    links = e.links
    links.should have(1).items
    links[0].omrl.should == "tx1"
  end

  specify "tx1 flow should exist and should be a flow and be linked" do
    e = Entity.find_named_entity("tx1")
    e.should_not be_nil
    Entity.get_entity_name(e.id).should == e.name
    e.entity_type.should == "flow"
  end
  
  specify "enmeshing a repeat JoinCurrency event should fail" do
    e = Event.create({
      :event_type => "JoinCurrency",
      :specification => <<-eos
        currency_omrl: bucks
        account_omrl: mwl
  eos
      })
    enmesh_result = e.enmesh
    e.errors.full_messages.should_not == []
    enmesh_result.should be_false
  end
  
  specify "creating a ca context should fail validation" do
    e = Entity.new({
      :entity_type => "context",
      :specification => <<-eos
        name: ca
        eos
    })
    e.should_not be_valid
  end
  specify "creating a ecuador context should be valid" do
    e = Entity.new({
      :entity_type => "context",
      :specification => <<-eos
        name: ec
        eos
    })
    e.should be_valid
  end
end


def create_root_context
  e = Entity.new({
    :entity_type => "context",
    :specification => <<-eos
      name: root
    eos
  })
  e.save
end

