require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Gradebook do
  before :all do
    @gradebook = test_client.course("6.006", 2011, :fall).gradebook
    @gradebook.assignments.add 'RSpec Test PS', 'rspec-test', 42
    @assignment = @gradebook.assignments.named('RSpec Test PS')
  end
  
  after :all do
    @assignment.delete!
  end
  
  describe '#students' do
    describe '#all' do
      let(:all) { @gradebook.students.all }
      
      it 'should have at least 1 student' do
        all.should have_at_least(1).student
      end
      
      it 'should only contain Student instances' do
        all.each do |student|
          student.should be_kind_of(Stellar::Gradebook::Student)
        end
      end
    end
    
    let(:test_name) { 'Christianne Swartz' }
    let(:test_email) { 'ude.tim@ytsirhc'.reverse }

    shared_examples_for 'a student query' do
      it 'should return a student' do
        student.should be_kind_of(Stellar::Gradebook::Student)
      end
      
      it 'should return a student with the correct name' do
        student.name.should == test_name
      end
      
      it 'should return a student with the correct email' do
        student.email.should == test_email
      end
    end
    
    describe '#named' do
      let(:student) { @gradebook.students.named test_name }
      
      it_should_behave_like 'a student query'
    end
    
    describe '#with_email' do
      let(:student) { @gradebook.students.with_email test_email }

      it_should_behave_like 'a student query'
    end
  end
end
