# :nodoc: namespace
module Stellar

# Stellar client scoped to a course's Members module.
class Members
  # Maps the text in navigation links to URI objects.
  #
  # Example: navigation['Homework'] => <# URI: .../ >
  attr_reader :navigation
  
  # The course whose membership is exposed by this client.
  attr_reader :course
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a Stellar client scoped to a course's Membership module.
  #
  # @param [Stellar::Course] the course whose membership info is desired
  def initialize(course)
    @course = course
    @client = course.client
    @url = course.navigation['Membership']
    
    page = @client.get_nokogiri @url
    @navigation = Hash[page.css('#toolBox dd a').map { |link|
      [link.inner_text.strip, URI.join(page.url, link['href'])]
    }]
  end

  # All member photos in this course's Membership module.
  # @return [Stellar::Gradebook::PhotoList] list of member photos for students
  def photos
    @students ||= Stellar::Members::PhotoList.new self
  end  

# Collection of member photos in a course's Membership module.
class PhotoList
  # Client scoped to the Membership module supplying this list of photos.
  attr_reader :course
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a list of member photos for a class.
  #
  # @param [Stellar::Members] members client scoped to a course's membership
  def initialize(members)
    @course = members.course
    @client = members.client
    
    @url = members.navigation['Member Photos']
    reload!
  end
  
  # All member photos listed in this course's Membership module.
  # @return [Array<Stellar::Members::Photo>] photos of students in this course
  def all
    @photos
  end
  
  # A photo in the course's Membership module.
  # @param [String] name the name of the desired member
  # @return [Stellar::Members::Photo] a photo for a member with the given name,
  #     or nil if no such member exists
  def named(name)
    @photos.find { |a| a.name == name }
  end

  # A photo in the course's Membership module.
  # @param [String] email the e-mail of the desired member
  # @return [Stellar::Members::Photo] a photo for a member with the given name,
  #     or nil if no such member exists
  def with_email(email)
    @photos.find { |a| a.email == email }
  end
  
  # Reloads the contents of this student list.
  #
  # @return [Stellar::Gradebook::StudentList] self, for easy call chaining
  def reload!
    photo_page = @client.get_nokogiri @url
    
    @photos = photo_page.css('#content .cols > div').map { |div|
      begin
        Stellar::Members::Photo.new div, @course
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
    
    self
  end
end  # class Stellar::Members::Photo

# Information about a member's photo
class Photo
  # The member's full name.
  attr_reader :name
  
  # The member's e-mail.
  attr_reader :email

  # URL of the member's photo.
  attr_reader :url
  
  # The course this member belongs to.
  attr_reader :course
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a Stellar client scoped to a student's Gradebook page.
  #
  # @param [Nokogiri::XML::Element] div a <div> representing a member's photo
  #     and info in the Members Photo page
  # @param [Stellar::Course] course Stellar client scoped to the
  #     course that this student belongs to
  def initialize(div, course)
    @course = course
    @client = course.client

    unless img = div.css('img[src*="pictures"]').first
      raise ArgumentError, 'Invalid photo-listing <div>'
    end
    @url = URI.join div.document.url, img['src'].gsub('/half/', '/full/') 
    unless mail_link = div.css('a[href*="mailto"]').first
      raise ArgumentError, 'Invalid photo-listing <div>'
    end
    @email = mail_link['href'].sub(/^mailto\:/, '')
    @name = mail_link.inner_text
  end
  
  # The member's photo bits.
  def data
    @client.get_file @url
  end
end  # class Stellar::Members::Photo

end  # class Stellar::Members

end  # namespace Stellar
