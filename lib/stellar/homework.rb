# :nodoc: namespace
module Stellar

# Homework listing functionality.
class HomeworkList
  # Creates a Stellar client scoped to a course's Homework module.
  #
  # @param [Stellar::Course] the course whose homework is desired
  def initialize(course)
    @course = course
    @client = course.client
    @url = course.navigation['Homework']
    
    page = @client.get_nokogiri @url
    @assignments = page.css('#content a[href*="assignment"]').map { |link|
      name = link.inner_text
      url = URI.join page.url, link['href']
      begin
        Stellar::Homework.new url, name, course
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
  end

  # All assignments in this course's homework module.
  # @return [Array<Stellar::Homework>] list of assignments posted by this course 
  def all
    @assignments
  end
  
  # An assignment in the course's homework module.
  # @param [String] name the name of the desired assignment
  # @return [Stellar::Homework] an assignment with the given name, or nil if no
  #     such assignment exists 
  def named(name)
    @assignments.find { |a| a.name == name }
  end
end  # class Stellar::HomeworkList

# One assignment in the homework tab.
class Homework
  # Assignment name.
  attr_reader :name
  
  # The course that this assignment is for.
  attr_reader :course
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a Stellar client scoped to an assignment.
  #
  # @param [URI, String] page_url URL to the assignment's main Stellar page
  # @param [String] assignment name, e.g. "name"
  # @param [Course] the course that issued the assignment
  def initialize(page_url, name, course)
    @name = name
    @url = page_url
    @course = course
    @client = course.client
    
    page = @client.get_nokogiri @url
    unless page.css('#content p b').any? { |dom| dom.inner_text.strip == name }
      raise ArgumentError, 'Invalid homework page URL'
    end
  end
  
  # List of submissions associated with this problem set.
  def submissions
    page = @client.get_nokogiri @url
    @submissions ||= page.css('.gradeTable tbody tr').map { |tr|
      begin
        Stellar::Homework::Submission.new tr, self
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
  end
  
# A student's submission for an assignment.
class Submission
  # URL to the last file that the student submitted.
  attr_reader :file_url
  
  # Submission time.
  attr_reader :time
  
  # Name of the student who authored this submission.
  attr_reader :name
  
  # Email of the student who authored this submission.
  attr_reader :email

  # Comments posted on this submission.
  attr_reader :comments
  
  # Homework that the submission belongs to.
  attr_reader :homework
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a submission from a <tr> element in the Stellar homework page.
  #
  # @param [Nokogiri::XML::Element] tr a <tr> element in the Stellar homework
  #     page describing this submission
  # @param [Stellar::Homework] homework Stellar client scoped to the assignment
  #     that this submission is for  
  def initialize(tr, homework)
    link = tr.css('a').find do |link|
      (/^\s*\d+\s*$/ =~ link.inner_text) && !(/grade/ =~ link['href'])
    end
    raise ArgumentError, 'Invalid submission-listing <tr>' unless link

    @url = URI.join tr.document.url, link['href']
    @homework = homework
    @client = homework.client
    
    page = @client.get_nokogiri @url

    unless author_link = page.css('#content h4 a[href^="mailto:"]').first
      raise ArgumentError, 'Invalid submission-listing <tr>'
    end
    @name = author_link.inner_text
    @email = author_link['href'].sub /^mailto:/, ''
    @file_url = page.css('#rosterBox a[href*="studentWork"]').map { |link|
      next nil unless link.inner_text == homework.name
      URI.join @url.to_s, link['href']
    }.reject(&:nil?).first
    @time = page.css('#rosterBox .instruction').map { |span|
      unless span.css('strong').any? { |strong| /date/i =~ strong.inner_text }
        next nil
      end
      time_string = span.inner_text.split(':', 2).last.strip
      time = DateTime.parse(time_string + ' GMT-4').to_time
    }.reject(&:nil?).first
    
    @add_comment_url = URI.join @url.to_s,
        page.css('#comments a[href*="add"]').first['href']
    reload_comments! page
  end
  
  # The contents of the file attached to this Stellar submission.
  #
  # @return [String] raw file data
  def file_data
    @client.get_file @file_url
  end
    
  # Adds a comment to the student's submission.
  #
  # @param [String] text the comment text
  # @param [String] file_data the content of the file attached to the comment;
  #     by default, no file is attached
  # @param [String] file_mime_type if a file is attached, indicates its type;
  #     examples: 'text/plain', 'application/pdf'
  # @param [String] file_name name of the file attached to the comment; by 
  #     default, 'attachment.txt'
  # @return [Stellar::Homework::Submission] self
  def add_comment(text, file_data = nil, file_mime_type = 'text/plain',
                  file_name = 'attachment.txt')
    add_page = @client.get @add_comment_url
    add_form = add_page.form_with :action => /addcomment/i
    
    add_form.field_with(:name => /newCommentRaw/i).value = text
    add_form.field_with(:name => /newComment/i).value = text
    add_form.checkbox_with(:name => /privateComment/i).checked = :checked
    if file_data
      upload = add_form.file_uploads.first
      upload.file_name = file_name
      upload.mime_type = file_mime_type
      upload.file_data = file_data
    end
    add_form.submit add_form.button_with(:name => /submit/i)
    self
  end
  
  # Reloads the problem set's comments page.
  def reload_comments!(page = nil)
    page ||= @client.get_nokogiri @url
    @comments = page.css('#comments ~ table.dataTable').map { |table|
      Comment.new table, self
    }.reject(&:nil?)
  end

# A comment on a Stellar submission.
class Comment
  # Person who posted the comment.
  attr_reader :author
  # Comment text.
  attr_reader :text
  # URL to the file attached to the comment. Can be nil.
  attr_reader :attachment_url
  # True if the comment was deleted.
  attr_reader :deleted
  # True if the comment was deleted.
  alias_method :deleted?, :deleted

  # The submission that the comment was posted on.
  attr_reader :submission
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a comment from a <table> in a Stellar submission details page.
  #
  # @param [Nokogiri::XML::Element] table a <table> element in a Stellar
  #     submission details showing this comment
  # @param [Stellar::Homework::Submission] submission Stellar client scoped to
  #     the submission that was commented on
  def initialize(table, submission)
    @submission = submission
    @client = @submission.client

    page_url = table.document.url
    @author = table.css('thead tr th.announcedBy').first.inner_text
    
    unless content = table.css('tbody tr td.announcement').first
      raise 'Invalid submission comment table'
    end
    if (deleted_text = table.css('tbody tr td.announcement > em').first) &&
        deleted_text.inner_text == 'deleted'
      @deleted = true
      @text = nil
      @attachment_url = nil
    else
      @deleted = false
      
      unless delete_link = table.css('thead a[href*="delete"]').first
        raise ArgumentError, 'Invalid submission comment table'
      end
      @delete_url = URI.join page_url, delete_link['href']
      @text = content.css('p').inner_text
      attachment_links = table.css('tbody tr td.announcement > a')
      if attachment_links.empty?
        @attachment_url = nil
      else
        @attachment_url = URI.join page_url, attachment_links.first['href']
      end
    end
  end
  
  # Deletes this comment from Stellar.
  def delete!
    return if @deleted
    delete_page = @client.get @delete_url
    delete_form = delete_page.form_with(:action => /delete/i)
    delete_button = delete_form.button_with(:name => /delete/i)
    delete_form.submit delete_button
    @deleted = true
  end
  
  # The contents of the file attached to this Stellar submission comment.
  #
  # @return [String] raw file data
  def attachment_data
    @attachment_url && @client.get_file(@attachment_url)
  end
end  # class Stellar::Homework::Submission::Comment
  
end  # class Stellar::Homework::Submission

end  # class Stellar::Homework

end  # namespace Stellar
