# :nodoc: namespace
module Stellar

# Stellar client scoped to a course's Gradebook module.
class Gradebook
  # Maps the text in navigation links to URI objects.
  #
  # Example: navigation['Homework'] => <# URI: .../ >
  attr_reader :navigation
  
  # The course whose Gradebook is exposed by this client.
  attr_reader :course
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a Stellar client scoped to a course's Gradebook module.
  #
  # @param [Stellar::Course] the course whose gradebook is desired
  def initialize(course)
    @course = course
    @client = course.client
    @url = course.navigation['Gradebook']
    
    page = @client.get_nokogiri @url
    @navigation = Hash[page.css('#toolBox.dashboard dd a').map { |link|
      [link.inner_text, URI.join(page.url, link['href'])]
    }]
  end

  # All assignments in this course's Gradebook module.
  # @return [Stellar::Gradebook::AssignmentList] list of assignments in this
  #     gradebook
  def assignments
    @assignments ||= Stellar::Gradebook::AssignmentList.new self
  end  

# Collection of assignments in a course's Gradebook module.
class AssignmentList
  # The course's 
  attr_reader :gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a list of Gradebook assignments for a class.
  #
  # @param [Stellar::Gradebook] gradebook client scoped to a course's Gradebook
  def initialize(gradebook)
    @gradebook = gradebook
    @client = gradebook.client
    
    @url = gradebook.navigation['Assignments']
    reload!
  end
  
  # All assignments in this course's Gradebook module.
  # @return [Array<Stellar::Gradebook::Assignment>] list of assignments posted
  #     by this course 
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
  
  # Reloads the contents of this assignment list.
  #
  # @return [Stellar::Gradebook::AssignmentList] self, for easy call chaining
  def reload!
    assignment_page = @client.get_nokogiri @url
    
    @assignments = assignment_page.css('.gradeTable tbody tr').map { |tr|
      begin
        Stellar::Gradebook::Assignment.new tr, self
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
    
    self
  end
  
  # Creates a new assignment in the Gradebook.
  #
  # @param [String] long_name the assignment's full name
  # @param [String] short_name a shorter name?
  # @param [Numeric] max_score maximum score that a student can receive
  # @param [Time] due_on date when the pset is due
  # @param [Numeric] weight score weight in total score for the course
  # @return [Stellar::Gradebook::AssignmentList] self, for easy call chaining
  def add(long_name, short_name, max_points, due_on = Time.today, weight = nil)
    add_page = @client.get @gradebook.navigation['Add Assignment']
    add_form = add_page.form_with :action => /new/i
    add_form.field_with(:name => /title/i).value = long_name
    add_form.field_with(:name => /short/i).value = short_name
    add_form.field_with(:name => /points/i).value = max_points.to_s
    add_form.field_with(:name => /short/i).value = due_on.strftime('%m.%d.%Y')
    if weight
      add_form.field_with(:name => /weight/i).value = weight.to_s
    end
    add_form.submit add_form.button_with(:class => /active/)
    
    reload!
  end
end  # class Stellar::Gradebook::AssignmentList

# One assignment in the Gradebook tab.
class Assignment
  # Assignment name.
  attr_reader :name
  
  # URL of the assignment's main page.
  attr_reader :url
  
  # True if the homework was deleted.
  attr_reader :deleted
  # True if the homework was deleted.
  alias_method :deleted?, :deleted
  
  # The gradebook that this assignment is in.
  attr_reader :gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a submission from a <tr> element in the Gradebook assignments page.
  #
  # @param [Nokogiri::XML::Element] tr a <tr> element in the Gradebook
  #     assignments page describing this assignment
  # @param [Stellar::Gradebook] gradebook Stellar client scoped to the
  #     course gradebook containing this assignment
  def initialize(tr, gradebook)
    @gradebook = gradebook
    @client = gradebook.client
    
    link = tr.css('a[href*=".html"]').find { |link| link.css('img').empty? }
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless link
    @name = link.inner_text
    @url = URI.join tr.document.url, link['href']
    
    page = client.get_nokogiri @url
    summary_table = page.css('.gradeTable').find do |table|
      /summary/i =~ table.css('caption').inner_text
    end
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless summary_table
    
    edit_link = summary_table.css('tbody tr a[href*="edit"]').first
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless edit_link
    @edit_url = URI.join @url.to_s, edit_link['href']
    
    @deleted = false
  end
  
  # Deletes this assignment from the Gradebook.
  def delete!
    return if @deleted
    
    edit_page = @client.get @edit_url
    edit_form = edit_page.form_with :action => /edit/i
    confirm_page = edit_form.submit edit_form.button_with(:name => /del/i)
    
    @deleted = true
    self
  end
end  # class Stellar::Gradebook::Assignment

# Collection of students in a course's Gradebook module.
class StudentList
  # The course's 
  attr_reader :gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a list of students in a class' Gradebook.
  #
  # @param [Stellar::Gradebook] gradebook client scoped to a course's Gradebook
  def initialize(gradebook)
    @gradebook = gradebook
    @client = gradebook.client
    
    @url = gradebook.navigation['Students']
    reload!
  end
  
  # All students listed in this course's Gradebook module.
  # @return [Array<Stellar::Gradebook::Student>] list of students in this course
  def all
    @students
  end
  
  # An assignment in the course's homework module.
  # @param [String] name the name of the desired assignment
  # @return [Stellar::Homework] a student with the given name, or nil if no such
  #     student exists
  def named(name)
    @students.find { |a| a.name == name }
  end
  
  # Reloads the contents of this student list.
  #
  # @return [Stellar::Gradebook::StudentList] self, for easy call chaining
  def reload!
    student_page = @client.get_nokogiri @url
    
    data_script = student_page.css('script').find do |script|
      /row\s*\=.*\;/ =~ script.inner_text
    end
    data = JSON.parse (/row\s*\=([^;]*)\;/).match(data_script.inner_text)[1]
    
    @students = data.map { |student_line|
      email = student_line[0]
      url = URI.join @url.to_s, student_line[1]
      name = student_line[2].split(',', 2).map(&:strip).reverse.join(' ')
      
      begin
        Stellar::Gradebook::Student.new tr, self
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
    
    self
  end
end  # class Stellar::Gradebook::StudentsList

# One assignment in the Gradebook tab.
class Assignment
  # Assignment name.
  attr_reader :name
  
  # URL of the assignment's main page.
  attr_reader :url
  
  # True if the homework was deleted.
  attr_reader :deleted
  # True if the homework was deleted.
  alias_method :deleted?, :deleted
  
  # The gradebook that this assignment is in.
  attr_reader :gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a submission from a <tr> element in the Gradebook assignments page.
  #
  # @param [Nokogiri::XML::Element] tr a <tr> element in the Gradebook
  #     assignments page describing this assignment
  # @param [Stellar::Gradebook] gradebook Stellar client scoped to the
  #     course gradebook containing this assignment
  def initialize(tr, gradebook)
    @gradebook = gradebook
    @client = gradebook.client
    
    link = tr.css('a[href*=".html"]').find { |link| link.css('img').empty? }
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless link
    @name = link.inner_text
    @url = URI.join tr.document.url, link['href']
    
    page = client.get_nokogiri @url
    summary_table = page.css('.gradeTable').find do |table|
      /summary/i =~ table.css('caption').inner_text
    end
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless summary_table
    
    edit_link = summary_table.css('tbody tr a[href*="edit"]').first
    raise ArgumentError, 'Invalid assignment-listing <tr>' unless edit_link
    @edit_url = URI.join @url.to_s, edit_link['href']
    
    @deleted = false
  end
  
  # Deletes this assignment from the Gradebook.
  def delete!
    return if @deleted
    
    edit_page = @client.get @edit_url
    edit_form = edit_page.form_with :action => /edit/i
    confirm_page = edit_form.submit edit_form.button_with(:name => /del/i)
    
    @deleted = true
    self
  end
end  # class Stellar::Gradebook::Assignment

# A student's submission for an assignment.
class Submission
  # URL to the last file that the student submitted.
  attr_reader :file_url
  
  # Name of the student who authored this submission.
  attr_reader :name
  
  # Email of the student who authorted this submission.
  attr_reader :email

  # Comments posted on this submission.
  attr_reader :comments
  
  # Gradebook that the submission belongs to.
  attr_reader :Gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a submission from a <tr> element in the Stellar Gradebook page.
  #
  # @param [Nokogiri::XML::Element]
  def initialize(tr, gradebook)
    link = tr.css('a').find { |link| /submission\s+details/ =~ link.inner_text }
    raise ArgumentError, 'Invalid submission-listing <tr>' unless link

    @url = URI.join tr.document.url, link['href']
    @gradebook = gradebook
    @client = gradebook.client
    
    page = @client.get_nokogiri @url

    unless author_link = page.css('#content h4 a[href^="mailto:"]').first
      raise ArgumentError, 'Invalud submission-listing <tr>'
    end
    @name = author_link.inner_text
    @email = author_link['href'].sub /^mailto:/, ''
    @file_url = page.css('#rosterBox a[href*="studentWork"]').map { |link|
      next nil unless link.inner_text == gradebook.name
      URI.join @url.to_s, link['href']
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
  # @return [Stellar::Gradebook::Submission] self
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
end  # class Stellar::Gradebook::Assignment::Submission::Comment
  
end  # class Stellar::Gradebook::Assignment::Submission

end  # class Stellar::Gradebook

end  # namespace Stellar
