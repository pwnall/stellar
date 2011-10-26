require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Client do
  let(:client) { Stellar::Client.new }
  
  shared_examples_for 'an authenticated client' do
    describe 'get_nokogiri' do
      let(:page) { client.get_nokogiri '/atstellar' }
      
      it 'should be a Nokogiri document' do
        page.should be_kind_of(Nokogiri::HTML::Document)
      end
      
      it 'should have course links' do
        page.css('a[title*="class site"]').length.should > 0
      end
    end
  end
  
  describe '#auth' do
    describe 'with Kerberos credentials' do
      before do
        client.auth :kerberos => test_mit_kerberos
      end
      
      it_should_behave_like 'an authenticated client'
    end
    
    describe 'with a certificate' do
      before do
        client.auth :cert => test_mit_cert
      end
      
      it_should_behave_like 'an authenticated client'
    end

    describe 'with bad Kerberos credentials' do
      it 'should raise ArgumentError' do
        lambda {
          client.auth :kerberos => test_mit_kerberos.merge(:pass => 'fail')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe '#course' do
    before do
      client.auth :kerberos => test_mit_kerberos
    end
    let(:six) { client.course('6.006', 2011, :fall) }
    
    it 'should return a Course instance' do
      six.should be_kind_of(Stellar::Course)
    end
    
    it 'should return a 6.006 course' do
      six.number.should == '6.006'
    end
  end
end
