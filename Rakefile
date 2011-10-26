# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "stellar"
  gem.homepage = "http://github.com/pwnall/stellar"
  gem.license = "MIT"
  gem.summary = %Q{Automated access to MIT's Stellar data}
  gem.description = %Q{So we don't have to put up with Stellar's craptastic ui}
  gem.email = "victor@costan.us"
  gem.authors = ["Victor Costan"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

# Fixtures.

require 'highline/import'
require 'readline'
require 'yaml'

task :spec => :fixtures

krb_file = 'spec/fixtures/kerberos.b64'
file krb_file do
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
  require 'stellar'

  kerberos = {}
  kerberos[:user] = ask('MIT Kerberos Username: ') { |q| q.echo = true }
  kerberos[:pass] = ask('MIT Kerberos Password: ') { |q| q.echo = '*' }
  kerberos[:mit_id] = ask('MIT ID: ') { |q| q.echo = true }
  # Verify the MIT information by trying to get a certificate.
  if Stellar::Auth.get_certificate kerberos
    File.open(krb_file, 'w') {|f| f.write [kerberos.to_yaml].pack('m') }
  end
end
task :fixtures => krb_file

cert_file = 'spec/fixtures/mit_cert.yml'
file cert_file => krb_file do
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
  require 'stellar'
  
  kerberos = YAML.load File.read(krb_file).unpack('m').first
  cert = Stellar::Auth.get_certificate kerberos
  yaml = {:cert => cert[:cert].to_pem, :key => cert[:key].to_pem}.to_yaml
  File.open(cert_file, 'wb') { |f| f.write yaml }
  
  # Write the certificate in PKCS#12 format for debugging purposes.
  p12 = OpenSSL::PKCS12.create(nil, 'MIT Stellar', cert[:key], cert[:cert])
  File.open('spec/fixtures/mit_cert.p12', 'wb') { |f| f.write p12.to_der }
end
task :fixtures => cert_file
