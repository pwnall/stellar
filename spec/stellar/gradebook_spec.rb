require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Gradebook do
  before :all do
    @gradebook = test_client.course("6.006", 2011, :fall).gradebook
  end
  
  describe 'navigation' do
    it 'should have an Assignments section' do
      @gradebook.navigation['Assignments'].should be_kind_of(URI)
    end
    
    it 'should have an Add Assignment section' do
      @gradebook.navigation['Add Assignment'].should be_kind_of(URI)
    end
  end
  
  describe 'assignments' do
    let(:assignments) { @gradebook.assignments }
    
    describe '#all' do
      it 'should have at least one assignment' do
        assignments.all.should have_at_least(1).assignment
      end
      
      it 'should have an assignment named Quiz 1' do
        assignments.named('Quiz 1').
                    should be_kind_of(Stellar::Gradebook::Assignment)
      end
    end
  end
end
