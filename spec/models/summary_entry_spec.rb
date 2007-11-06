require File.dirname(__FILE__) + '/../spec_helper'

describe 'Balance' do
  before(:each) do
    @flow1 = {
      :declaring_account => 'zippy^us',
      :accepting_account => 'mwl^ca',
      :taxable => true,
      :description => 'Some thing',
      :amount => "22",
      :currency => 'bucks~us'
    }
    @flow2 = {
      :declaring_account => 'mwl^ca',
      :accepting_account => 'zippy^us',
      :taxable => false,
      :description => 'Some else back',
      :amount => "2",
      :currency => 'bucks~us'
    }
    @flow3 = {
      :declaring_account => 'zippy^us',
      :accepting_account => 'ey^ca',
      :taxable => false,
      :description => 'Something to Ernie',
      :amount => "10",
      :currency => 'bucks~us'
    }
    s = SummaryEntry.new()
  end

  it "should create a new balance from a flow specification" do
    balance = Balance.create(@flow1,:amount,:accepting_account)
    balance.volume.should == 22
    balance.balance.should == 22
    balance.count.should == 1
  end
  
  it "should apply a flow to balance" do
    balance = Balance.create(@flow1,:amount,:accepting_account)
    balance.apply(@flow1,:amount,:declaring_account)
    balance.volume.should == 44
    balance.balance.should == 0
    balance.count.should == 2
  end
  
#  it "should update balances from a flow specification" do
#    (b1,b2) = Balance.build_summaries(@flow1)
#  end

  it "should return the summary snapshot for a flow specification" do
    b = Balance.update_summaries(:amount,@flow1)
    b.should == {
      'zippy^us' => {'balance' => -22.0, 'volume' => 22.0, 'count' => 1},
      'mwl^ca' => {'balance' => 22.0, 'volume' => 22.0, 'count' => 1}
    }
  end

  it "should update summary entry from a flow specification" do
    Balance.update_summaries(:amount,@flow1)
    Balance.update_summaries(:amount,@flow2)
    Balance.update_summaries(:amount,@flow3)
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','zippy^us','bucks~us'])
    last_zippy_time = s.updated_at
    s.summary.balance.should == -30
    s.summary.volume.should == 34
    s.summary.count.should == 3
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','mwl^ca','bucks~us'])
    s.updated_at.should_not == last_zippy_time
    s.summary.balance.should == 20
    s.summary.volume.should == 24
    s.summary.count.should == 2
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','ey^ca','bucks~us'])
    s.updated_at.should == last_zippy_time
    s.summary.balance.should == 10
    s.summary.volume.should == 10
    s.summary.count.should == 1
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','us.','bucks~us'])
    s.updated_at.should == last_zippy_time
    s.summary.balance.should == -30
    s.summary.volume.should == 34
    s.summary.count.should == 3
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','ca.','bucks~us'])
    s.updated_at.should == last_zippy_time
    s.summary.balance.should == 30
    s.summary.volume.should == 34
    s.summary.count.should == 3
  end
end
