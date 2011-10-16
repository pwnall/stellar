require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Homework::Submission do
  before(:all) do
    @submissions = test_client.course('6.006', 2011, :fall).homework.
        named('Problem Set 1').submissions
  end
  
  let(:one) { @submissions.find { |s| s.name == 'Christianne B. Swartz' } }

  it "should have the author's name" do
    one.name.should == 'Christianne B. Swartz'
  end
  it "should have the author's email" do
    one.email.reverse.should == 'ude.tim@ytsirhc'
  end
  it 'should have a submission URL' do
    one.file_url.should be_kind_of(URI)
  end
  it 'should have the right bits in the submission' do
    one.file_data.should match(/\% 6\.006/)
  end  
  
  it 'should have at least one feedback comment' do
    one.comments.should have_at_least(1).comment
  end 
  
  describe Stellar::Homework::Submission::Comment do
    let(:comment) { one.comments.first }
    
    it 'should have an author' do
      comment.author.should == 'Sarah Charmian Eisenstat'
    end
    it 'should have some text' do
      comment.text.should match(/see attached/i)
    end
    it 'should have an attachment' do
      comment.attachment_url.should be_kind_of(URI)
    end
    
    it 'should have the right bits in the attachment' do
      comment.attachment_data.should match(/^\%PDF\-.*\%\%EOF/m)
    end
  end
  
  describe '#add_comment with no file' do
    before :all do
      @text = 'Testing... please ignore this.'
      @old_comments = one.comments
      @result = one.add_comment @text
      one.reload_comments!
    end
    after :all do
      one.comments.last.delete!
    end
    
    it 'should create a new comment' do
      one.comments.length.should == @old_comments.length + 1
    end
    
    it 'should have the right text in the new comment' do
      one.comments.last.text.should == @text
    end
    
    it 'should not have an attachment in the new comment' do
      one.comments.last.attachment_url.should be_nil
    end
  end
  
  describe '#add_comment with file' do
    before :all do
      @text = 'Testing... please ignore the attachment.'
      @file_data = 'Please ignore this testing file.'
      
      @old_comments = one.comments
      @result = one.add_comment @text, @file_data
      one.reload_comments!
    end
    after :all do
      one.comments.last.delete!
    end
    
    it 'should create a new comment' do
      one.comments.length.should == @old_comments.length + 1
    end
    
    it 'should have the right text in the new comment' do
      one.comments.last.text.should == @text
    end
    
    it 'should have an attachment in the new comment' do
      one.comments.last.attachment_url.should_not be_nil
    end
    
    it 'should have the right attachment bits' do
      one.comments.last.attachment_data.should == @file_data
    end
  end
  
  describe '#delete_comment' do
    before :all do
      @old_comments = one.comments
      @result = one.add_comment @text
      one.reload_comments!
      @comment = one.comments.last
      @comment.delete!
      one.reload_comments!
    end
    
    it 'should remove that last comment' do
      one.comments.reject(&:deleted?).length.should ==
          @old_comments.reject(&:deleted?).length
    end
    
    it 'should keep the right comments' do
      one.comments.reject(&:deleted?).map(&:text).should ==
          @old_comments.reject(&:deleted?).map(&:text)
    end
    
    it 'should mark the comment as deleted' do
      @comment.should be_deleted
    end
  end
end
