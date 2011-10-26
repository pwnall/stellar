require 'logger'

# :nodoc: namespace
module Stellar

# Support for authentication on MIT systems.
module Auth
  # Path to the MIT CA self-signed certificate.
  def mitca_path
    File.join File.dirname(__FILE__), 'mitca.crt'
  end
  
  # Authenticates using some credentials, e.g. an MIT certificate.
  #
  # @param [Hash] options credentials to be used for authentication
  # @option options [String] :cert path to MIT client certificate for the user
  # @option options [Hash] :kerberos:: Kerberos credentials, encoded as a Hash
  #     with :user and :pass keys
  # @return [Stellar::Client] self, for convenient method chaining
  def auth(options = {})
    # Create new Mechanize instance to drop any old credentials.
    
    if options[:cert]
      key = options[:cert][:key]
      if key.respond_to?(:to_str) && !File.exist?(key)
        key = OpenSSL::PKey::RSA.new key
      end
      cert = options[:cert][:cert]
      if cert.respond_to?(:to_str) && !File.exist?(cert)
        cert = OpenSSL::X509::Certificate.new cert
      end
      
      @mech = mech do |m|
        m.key = key
        m.cert = cert
      end
    else
      @mech = mech
    end
    
    # Go to a page that is guaranteed to redirect to shitoleth.
    step1_page = get '/atstellar'
    # Fill in the form.
    step1_form = step1_page.form_with :action => /WAYF/
    step1_form.checkbox_with(:name => /perm/).checked = :checked
    step2_page = step1_form.submit step1_form.buttons.first
    # Click through the stupid confirmation form.
    step2_form = step2_page.form_with :action => /WAYF/
    cred_page = step2_form.submit step2_form.button_with(:name => /select/i)
    
    # Fill in the credentials form.
    if options[:cert]
      cred_form = cred_page.form_with :action => /certificate/i
      cred_form.checkbox_with(:name => /pref/).checked = :checked
    elsif options[:kerberos]
      cred_form = cred_page.form_with :action => /username/i
      cred_form.field_with(:name => /user/).value = options[:kerberos][:user]
      cred_form.field_with(:name => /pass/).value = options[:kerberos][:pass]
    else
      raise ArgumentError, 'Unsupported credentials'
    end
    
    # Click through the SAML response form.
    saml_page = cred_form.submit cred_form.buttons.first
    unless saml_form = saml_page.form_with(:action => /SAML/)
      raise ArgumentError, 'Authentication failed due to invalid credentials'
    end
    saml_form.submit
    
    self
  end
end  # module Stellar::Auth
  
# :nodoc: class methods
module Auth
  class <<self
    include Auth
    
    # Obtains a certificate using a Kerberos credentials.
    #
    # @param [Hash] kerberos MIT Kerberos credentials
    # @option kerberos [String] :user the Kerberos username (e.g. "costan")
    # @option kerberos [String] :pass the Kerberos password (handle with care!)
    # @option kerberos [String] :mit_id 9-character string or 9-digit number
    #                                   starting with 9 (9........)
    # @option kerberos [Fixnum] :ttl certificate lifetime, in days (optional;
    #                                            defaults to 1 day)
    #
    # @return [Hash] a Hash with a :cert key (the OpenSSL::X509::Certificate)
    #     and a :key key (the matching OpenSSL::PKey::PKey private key)
    def get_certificate(kerberos)
      mech = Mechanize.new do |m|
        m.user_agent_alias = 'Linux Firefox'
        # NOTE: ca.mit.edu uses a Geotrust certificate, not the self-signed one
      end
      login_page = mech.get 'https://ca.mit.edu/ca/'
      login_form = login_page.form_with :action => /login/
      login_form.field_with(:name => /login/).value = kerberos[:user]
      login_form.field_with(:name => /pass/).value = kerberos[:pass]
      login_form.field_with(:name => /mitid/).value = kerberos[:mit_id]
      keygen_page = login_form.submit login_form.buttons.first

      keygen_form = keygen_page.form_with(:action => /ca/)
      if /login/ =~ keygen_form.action
        raise ArgumentError, 'Invalid Kerberos credentials'
      end
      keygen_form.field_with(:name => /life/).value = kerberos[:ttl] || 1
      key_pair = keygen_form.keygens.first.key
      response_page = keygen_form.submit keygen_form.buttons.first
      
      cert_frame = response_page.frame_with(:name => /download/)
      cert_bytes = mech.get_file cert_frame.uri
      cert = OpenSSL::X509::Certificate.new cert_bytes
      {:key => key_pair, :cert => cert}
    end
  end
end  # module Stellar::Auth

end  # namespace Stellar
