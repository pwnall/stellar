require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Stellar do
  describe '#client' do
    let(:client) { Stellar.client }
    
    it 'should be a Stellar client' do
      client.should be_kind_of(Stellar::Client)
    end
  end
end
