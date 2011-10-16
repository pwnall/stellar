require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stellar::Auth do
  describe 'get_certificate' do
    before :all do
      @result = Stellar::Auth.get_certificate test_mit_kerberos
    end
    
    it 'should contain a key pair' do
      @result[:key].should be_kind_of(OpenSSL::PKey::PKey)
      @result[:key].should be_private
    end
    it 'should contain a certificate' do
      @result[:cert].should be_kind_of(OpenSSL::X509::Certificate)
    end
    it 'should contain a MIT certificate' do
      @result[:cert].subject.to_s.
                     should match(/O=Massachusetts Institute of Technology/)
    end
    it 'should contain a certificate matching the key' do
      @result[:cert].public_key.to_pem.should == @result[:key].public_key.to_pem
    end
  end
  
  describe 'get_certificate with bad credentials' do
    it 'should raise ArgumentError' do
      lambda {
        Stellar::Auth.get_certificate test_mit_kerberos.merge(:pass => 'fail')
      }.should raise_error(ArgumentError)
    end
  end
end
