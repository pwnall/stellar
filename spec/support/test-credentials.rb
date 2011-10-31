require 'yaml'

# The MIT kerberos used to run tests.
def test_mit_kerberos
  path = File.expand_path '../fixtures/kerberos.b64', File.dirname(__FILE__)
  YAML.load File.read(path).unpack('m').first
end

# The MIT certificate used to run tests.
def test_mit_cert
  path = File.expand_path '../fixtures/mit_cert.yml', File.dirname(__FILE__)
  YAML.load File.read(path)
end

# Cached client authenticated through some means.
def test_client
  TestCredentialsCache.test_client
end

class TestCredentialsCache
  def self.test_client
    @__test_client ||= Stellar::Client.new.auth :cert => test_mit_cert  
  end
end
