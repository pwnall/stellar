# :nodoc: namespace
module Stellar

# Course search functionality.
class Courses
  def initialize(client)
    @client = client
  end

  # My classes.
  # @return [Array] array with one Hash per class; Hashes have :number and
  #                 :url keys
  def mine
    page = @client.get_nokogiri '/atstellar'
    class_links = page.css('a[href*="/S/course/"]').
        map { |link| Stellar::Course.from_link link, @client }.reject(&:nil?)
  end
end  # class Stellar::Courses

# Stellar client scoped to a course.
class Course
  # Official MIT course ID, e.g. "6.006".
  attr_reader :number
  
  # URL to the course's main page on Stellar.
  #
  # Example: "https://stellar.mit.edu/S/course/6/fa11/6.006/"
  attr_reader :url
  
  # Maps the text in navigation links to URI objects.
  #
  # Example: navigation['Homework'] => <# URI: .../ >
  attr_reader :navigation
  
  # True if the client has administrative rights for this course.
  attr_reader :is_admin
  
  # The generic Stellar client used to query the server.
  attr_reader :client
  
  # Creates a scoped Stellar client from a link to the course's page.
  #
  # @param [Nokogiri::XML::Element] nokogiri_link a link pointing to the
  #                                               course's main page 
  # @param [Stellar::Client] client generic Stellar client
  # @return [Stellar::Course] client scoped to the course, or nil if the link
  #                                  is not valid
  def self.from_link(nokogiri_link, client)
    number = nokogiri_link.css('span.courseNo').inner_text
    return nil if number.empty?
    url = nokogiri_link['href']
    return nil unless url.index(number)
    return nil unless /\/S\/course\// =~ url
    
    return self.new(client, url, number)
  end
  
  # Creates a scoped Stellar client from a link to the course's page.
  #
  # @param [String] number the official MIT course ID, e.g. "6.006"
  # @param [Fixnum] year the year the course was taught e.g. 2011 
  # @param [Symbol] semester :fall, :iap, :spring, :summer
  # @return [Stellar::Course] client scoped to the course
  def self.for(number, year, semester, client)
    semester_string = case semester
    when :fall
      'fa'
    when :spring
      'sp'
    when :summer
      'su'
    when :iap
      'ia'
    end
    term = "#{semester_string}#{year.to_s[-2..-1]}"
    major = number.split('.', 2).first
    url = "/S/course/#{major}/#{term}/#{number}/index.html"
    
    return self.new(client, url, number)
  end
  
  # Creates a scoped Stellar client from detailed specifications.
  #
  # @param [Stellar::Client] client generic Stellar client
  # @param [String] course_url HTTP URI to the course's main Stellar page
  # @param [String] course_number official course ID, e.g. "6.006"
  # @raise ArgumentError if the course URL does not point to a course page
  def initialize(client, course_url, course_number)
    @client = client
    @url = course_url
    @number = course_number
    
    course_page = @client.get_nokogiri course_url
    
    @is_admin = course_page.css('p#toolset').length > 0
    
    navbar_elems = course_page.css('#mainnav')
    unless navbar_elems.length == 1
      raise ArgumentError, "#{course_url} is not a course page"
    end
    @navigation = Hash[navbar_elems.first.css('a').map do |link|
      [link.inner_text.strip, URI.join(course_page.url, link['href'])]
    end]
  end
  
  # Client scoped to the course's Homework module.
  def homework
    @homework ||= Stellar::HomeworkList.new self
  end
  
  # Client scoped to the course's Gradebook module.
  def gradebook
    @gradebook ||= Stellar::Gradebook.new self
  end

  # Client scoped to the course's Members module.
  def members
    @members ||= Stellar::Members.new self
  end
end  # class Stellar::Course

end  # namespace Stellar
