require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Members do
  before :all do
    @members = test_client.course("6.006", 2011, :fall).members
  end
  
  describe '#navigation' do
    it 'should have a Member Photos section' do
      @members.navigation['Member Photos'].should be_kind_of(URI)
    end
  end

  describe '#photos' do
    before :all do
      @photos = @members.photos
    end

    describe '#all' do
      let(:all) { @photos.all} 
    end 
    
    shared_examples_for 'a photo' do
      it "should have the member's name" do
        one.name.should == 'Christianne B. Swartz'
      end
      it "should have the member's email" do
        one.email.reverse.should == 'ude.tim@ytsirhc'
      end
      it 'should have a photo URL' do
        one.url.should be_kind_of(URI)
      end
      it 'should have the right bits in the photo' do
        one.data.should match(/JFIF/)
      end
    end

    describe '#named' do
      let(:one) { @photos.named('Christianne B. Swartz') }      
      it_should_behave_like 'a photo'
    end
    describe '#with_email' do
      let(:one) { @photos.with_email('ude.tim@ytsirhc'.reverse) }      
      it_should_behave_like 'a photo'
    end
  end
end
