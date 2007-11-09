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
  
  it "should return the summary snapshot for a flow specification" do
    b = Summary.update_summaries('Balance',:amount,@flow1)
    {'balance' => -22.0, 'volume' => 22.0, 'count' => 1}.each {|k,v| b['zippy^us'][k].should == v}
    {'balance' => 22.0, 'volume' => 22.0, 'count' => 1}.each {|k,v| b['mwl^ca'][k].should == v}
  end

  it "should update summary entry from a flow specification" do
    Summary.update_summaries('Balance',:amount,@flow1)
    Summary.update_summaries('Balance',:amount,@flow2)
    Summary.update_summaries('Balance',:amount,@flow3)
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

describe 'Average' do
  before(:each) do
    @flow1 = {
      :declaring_account => 'zippy^us',
      :accepting_account => 'mwl^ca',
      :rating => "1",
      :currency => 'cred~us'
    }
    @flow2 = {
      :declaring_account => 'ey^ca',
      :accepting_account => 'mwl^ca',
      :rating => "2",
      :currency => 'cred~us'
    }
    @flow3 = {
      :declaring_account => 'mwl^ca',
      :accepting_account => 'ey^ca',
      :rating => "3",
      :currency => 'cred~us'
    }
    s = SummaryEntry.new()
  end

  it "should create a new average from a flow specification" do
    avg = Average.create(@flow1,:rating,:accepting_account)
    avg.average_declared.should == nil
    avg.average_accepted.should == 1
    avg.count_declared.should == 0
    avg.count_accepted.should == 1
  end
  
  it "should apply a flow to an existing summary" do
    avg = Average.create(@flow1,:rating,:accepting_account)
    avg.apply(@flow2,:rating,:accepting_account)
    avg.average_declared.should == nil
    avg.average_accepted.should == 1.5
    avg.count_declared.should == 0
    avg.count_accepted.should == 2
    avg.apply(@flow3,:rating,:declaring_account)
    avg.average_declared.should == 3
    avg.average_accepted.should == 1.5
    avg.count_declared.should == 1
    avg.count_accepted.should == 2
  end
  
  it "should return the summary snapshot for a flow specification" do
    a = Summary.update_summaries('Average',:rating,@flow1)
    {'average_declared' => 1, 'average_accepted' => nil, 'count_declared' => 1, 'count_accepted' => 0}.each {|k,v| a['zippy^us'][k].should == v}
    {'average_declared' => nil, 'average_accepted' => 1, 'count_declared' => 0, 'count_accepted' => 1}.each {|k,v| a['mwl^ca'][k].should == v}
  end

  it "should update summary entry from a flow specification" do
    Summary.update_summaries('Average',:rating,@flow1)
    Summary.update_summaries('Average',:rating,@flow2)
    Summary.update_summaries('Average',:rating,@flow3)
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','zippy^us','cred~us'])
    last_zippy_time = s.updated_at
    s.summary.average_declared.should == 1
    s.summary.average_accepted.should == nil
    s.summary.count_declared.should == 1
    s.summary.count_accepted.should == 0
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','mwl^ca','cred~us'])
#    s.updated_at.should_not == last_zippy_time
    s.summary.average_declared.should == 3
    s.summary.average_accepted.should == 1.5
    s.summary.count_declared.should == 1
    s.summary.count_accepted.should == 2
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','ey^ca','cred~us'])
#    s.updated_at.should == last_zippy_time
    s.summary.average_declared.should == 2
    s.summary.average_accepted.should == 3
    s.summary.count_declared.should == 1
    s.summary.count_accepted.should == 1
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','us.','cred~us'])
    s.updated_at.should == last_zippy_time
    s.summary.average_declared.should == 1
    s.summary.average_accepted.should == nil
    s.summary.count_declared.should == 1
    s.summary.count_accepted.should == 0
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','ca.','cred~us'])
#    s.updated_at.should == last_zippy_time
    s.summary.average_declared.should == (2+3.0)/2
    s.summary.average_accepted.should == 2
    s.summary.count_declared.should == 2
    s.summary.count_accepted.should == 3
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?','cred~us','cred~us'])
#    s.updated_at.should == last_zippy_time
    s.summary.average_declared.should == nil
    s.summary.average_accepted.should == 2
    s.summary.count_declared.should == 0
    s.summary.count_accepted.should == 3
  end
end