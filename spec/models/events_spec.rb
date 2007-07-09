require File.dirname(__FILE__) + '/../spec_helper'
require 'pp'
module EventSpecHelper
  def valid_attributes
    { :event_type => 'CreateAccount',
      :specification => "some spec"}
  end
end

describe "An event (in general)" do
  include EventSpecHelper

  before(:each) do
    @p = Event.new
  end

  it "should be invalid without an event_type" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :event_type}
    @p.should_not be_valid
  end

  it "should be invalid without a specification" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :specification}
    @p.should_not be_valid
  end

  it "should be valid with a full set of valid attributes" do
    @p.attributes = valid_attributes
    @p.should be_valid
  end
end

describe "Creating and enmeshing a context event" do
#  fixtures :entities
  before(:each) do
    Link.destroy_all
    Entity.destroy_all
    @root = create_root_context
    
    @e = Event.create({
        :event_type => "CreateContext",
        :specification => <<-eos
parent_context: .
name: ec
context_specification:
  description: Ecuador
eos
      })
    @enmesh_result = @e.enmesh
  end
  
  it "(root context should be created)" do
    @root.id.should == 1
    @root.errors.full_messages.should == []
  end

  it "should create a CreateContext event" do
    @e.should be_an_instance_of(Event::CreateContext)
  end

  it "should succeed" do
    @enmesh_result.should be_true
  end
  
  it "should produce no errors" do
    @e.errors.full_messages.should == []
  end
  
  it "should create a context entity" do
    e = Entity.find_by_omrl("ec.")
    e.should_not be_nil
    e.entity_type.should == "context"
  end

  it "which should be available through created_entity" do
    e = Entity.find_by_omrl("ec.")
    @e.created_entity.should == e
  end
    
end

describe "Given root,ca & us context; mwl.ca & zippy.us accounts joined to bucks currency and tx1 flow in bucks from zippy to mwl, THEN:" do
  fixtures :events

  before(:each) do
    Link.destroy_all
    Entity.destroy_all
    create_root_context
    e = Event.find(:all)
    e.each do |event|
      evt = Event.create({:event_type => event.event_type,:specification => event.specification})
      evt.enmesh
#      if e.event_type == "AcknowledgeFlow"
#        @flow = evt.created_entity
#      end
#      puts "specification: "<<event.specification
#      if !evt.errors.empty?
#        puts "ERROR: enmeshing event #{evt.errors.full_messages.join(",")} \n" 
#        pp evt
#      end
    end
  end
  
  it "canada context should exist and should be a context and be correctly linked" do
    e = Entity.find_by_omrl("ca.")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(1).items
    links[0].link_type.should == "names"
    links[0].specification_attribute("name") == "mwl"
  end

  it "us context should exist and should be a context and be correctly linked" do
    e = Entity.find_by_omrl("us.")
    e.should_not be_nil
    e.entity_type.should == "context"
    links = e.links
    links.should have(3).items
    links[0].link_type.should == "names"
    links[0].specification_attribute("name").should == "zippy"
    links[1].link_type.should == "names"
    links[1].specification_attribute("name") == "bucks"
  end

  it "bucks currency should exist and be linked to context, accounts and flow" do
    e = Entity.find_by_omrl("bucks~us.")
    e.should_not be_nil
    e.entity_type.should == "currency"
    links = e.links
#    links.should == ""
    links.should have(4).items
    links[0].link_type.should == "originates_from"
    links[0].omrl.should == "zippy^us."
    links[1].link_type.should == "is_used_by"
    links[1].omrl.should == "zippy^us."
    links[2].link_type.should == "is_used_by"
    links[2].omrl.should == "mwl^ca."
    links[3].link_type.should == "approves"
    links[3].omrl.should =~ /zippy\#[0-9]+/
  end

  it "ecuador context should not exist" do
    Entity.find_by_omrl("ec.").should == nil
  end

  it "mwl account should exist and should be an account and linked to flow tx1" do
    e = Entity.find_by_omrl("mwl^")
    e.should_not be_nil
    e.entity_type.should == "account"
    links = e.links
    links.should have(1).items
    links[0].omrl.should =~ /zippy\#[0-9]+/
  end

  it "should not be possible to enmesh a repeat CreateContext event (dup)" do
    e = Event.create({
        :event_type => "CreateContext",
        :specification => <<-eos
          context_specification:
            description: Canada
          parent_context: .
          name: ca
    eos
        })
    enmesh_result = e.enmesh
    e.errors.full_messages.should == ["Specification - enmeshing error: couldn't create the link! Specification name 'ca' already exists"]
    enmesh_result.should be_false
  end
  
  it "enmeshing a repeat JoinCurrency event should fail" do
    e = Event.create({
      :event_type => "JoinCurrency",
      :specification => <<-eos
        currency: bucks~us.
        account: mwl^ca
  eos
      })
    enmesh_result = e.enmesh
    e.errors.full_messages.should == ["Specification - enmeshing error: duplicate link attempt: bucks~us. already is_used_by mwl^ca."]
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

