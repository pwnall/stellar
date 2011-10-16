require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::HomeworkList do
  let(:six) { test_client.course("6.006", 2011, :fall) }
  let(:homework) { six.homework }
  
  describe 'all' do
    let(:all) { homework.all }
        
    it 'should have at least one assignment' do
      all.should have_at_least(1).assignment
    end
    
    it 'should have a Stellar::Homework in each assignment' do
      all.each do |c|
        c.should be_kind_of(Stellar::Homework)
      end
    end
  end
end

describe Stellar::Homework do
  let(:six) { test_client.course("6.006", 2011, :fall) }
  let(:ps1) { six.homework.named('Problem Set 1') }

  it 'should have a name' do
    ps1.name.should == 'Problem Set 1'
  end
  it 'should have a course' do
    ps1.course.should == six
  end
end
