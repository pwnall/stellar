# Standard library.
require 'openssl'
require 'uri'

# Gems.
require 'json'
require 'nokogiri'
require 'mechanize'

# TODO(pwnall): documentation
module Stellar
  # Creates a generic Stellar client.
  # @see Stellar::Client
  # @return [Stellar::Client] new generic Stellar client
  def self.client
    Stellar::Client.new
  end
end  # namespace Stellar

# Code.
require 'stellar/auth.rb'
require 'stellar/client.rb'
require 'stellar/courses.rb'
require 'stellar/gradebook.rb'
require 'stellar/homework.rb'
