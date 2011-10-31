require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Courses do
  let(:courses) { test_client.courses }
  
  describe '#mine' do
    let(:mine) { courses.mine }
        
    it 'should have at least one course' do
      mine.should have_at_least(1).course
    end
    
    it 'should have a dot in each course number' do
      mine.each do |c|
        c.number.should match('.')
      end
    end
    
    it 'should have the course number in each URL' do
      mine.each do |c|
        c.url.should match(c.number)
      end
    end
  end
end

describe Stellar::Course do
  before :all do
    @six = test_client.course("6.006", 2011, :fall)
  end
  
  describe '#navigation' do
    let(:nav) { @six.navigation }
    
    it 'should have a Gradebook link' do
      nav['Gradebook'].should be_kind_of(URI)
    end

    it 'should have a Homework link' do
      nav['Homework'].should be_kind_of(URI)
    end

    it 'should have a Membership link' do
      nav['Membership'].should be_kind_of(URI)
    end
  end
end
