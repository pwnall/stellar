require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Gradebook do
  before :all do
    @gradebook = test_client.course("6.006", 2011, :fall).gradebook
  end
  
  describe '#navigation' do
    it 'should have an Assignments section' do
      @gradebook.navigation['Assignments'].should be_kind_of(URI)
    end
    
    it 'should have an Add Assignment section' do
      @gradebook.navigation['Add Assignment'].should be_kind_of(URI)
    end

    it 'should have a Students section' do
      @gradebook.navigation['Students'].should be_kind_of(URI)
    end
  end
  
  let(:assignments) { @gradebook.assignments }

  describe '#assignments' do    
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
  
  describe '#add_assignment' do
    before do
      @old_length = assignments.all.length
      assignments.add 'RSpec Test PS', 'rspec-test', 42,
          Time.now + 5, 1.01
    end
    
    after do
      assignment = assignments.named('RSpec Test PS')
      assignment.delete!
    end
    
    it 'should create a new assignment' do
      assignments.all.length.should == 1 + @old_length
    end

    it 'should create an assignment with the right name' do
      assignments.named('RSpec Test PS').
                  should be_kind_of(Stellar::Gradebook::Assignment)
    end
  end
  
  describe Stellar::Gradebook::Assignment do
    before do
      assignments.add 'RSpec Test PS', 'rspec-test',
          42, Time.now + 5, 1.01
      @assignment = assignments.named 'RSpec Test PS'
    end
    
    after { @assignment.delete! }
    
    it 'should have a name' do
      @assignment.name.should == 'RSpec Test PS'
    end
    
    it 'should have an URL' do
      @assignment.url.should be_kind_of(URI)
    end
    
    it 'should not be deleted' do
      @assignment.should_not be_deleted
    end
    
    describe '#delete!' do
      before do
        @old_length = assignments.all.length
        @assignment.delete!
        assignments.reload!
      end
      
      it 'should remove an assignment' do
        assignments.all.length.should == @old_length - 1
      end
      
      it 'should remove the correct assignment' do
        assignments.named('RSpec Test PS').should be_nil
      end
      
      it 'should mark the assignment deleted' do
        @assignment.should be_deleted
      end
    end
  end
end
