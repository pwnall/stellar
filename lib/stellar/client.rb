# :nodoc: namespace
module Stellar

# Client session for accessing the Stellar API.
class Client
  include Stellar::Auth

  # Client for accessing public information.
  #
  # Call auth to authenticate as a user and access restricted functionality.
  def initialize
    @mech = mech
    
    @courses = nil
  end
  
  # New Mechanize instance.
  def mech(&block)
    m = Mechanize.new do |m|
      m.cert_store = OpenSSL::X509::Store.new
      m.cert_store.add_file mitca_path
      m.user_agent_alias = 'Linux Firefox'
      yield m if block
      m
    end
    m
  end

  # Fetches a page from the Stellar site.
  #
  # @param [String] path relative URL of the page to be fetched
  # @return [Mechanize::Page] the desired page, wrapped in the Mechanize API
  def get(path)
    uri = URI.join('https://stellar.mit.edu', path)
    page_bytes = @mech.get uri
  end

  # Fetches a page from the Stellar site.
  #
  # @param [String] path relative URL of the page to be fetched
  # @return [Nokogiri::HTML::Document] the desired page, parsed with Nokogiri
  def get_nokogiri(path)
    uri = URI.join('https://stellar.mit.edu', path)
    raw_html = @mech.get_file uri
    Nokogiri.HTML raw_html, uri.to_s
  end
  
  # Fetches a file from the Stellar site.
  #
  # @param [String] path relative URL of the file to be fetched
  # @return [String] raw contents of the file
  def get_file(path)
    uri = URI.join('https://stellar.mit.edu', path)
    @mech.get_file uri
  end
  
  # A Stellar client specialized to answer course queries.
  #
  # @return [Stellar::Courses] client specialized to course queries
  def courses
    @courses ||= Stellar::Courses.new self
  end
  
  # (see Stellar::Course#for)
  def course(number, year, semester)
    Stellar::Course.for number, year, semester, self
  end
end  # class Stellar::Client
  
end  # namespace Stellar
