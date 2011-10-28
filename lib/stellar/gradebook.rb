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

  # All students in this course's Gradebook module.
  # @return [Stellar::Gradebook::StudentList] list of students in this gradebook
  def students
    @students ||= Stellar::Gradebook::StudentList.new self
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
  def add(long_name, short_name, max_points, due_on = Time.now, weight = nil)
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
  
  # A student in the course's Gradebook module.
  # @param [String] name the name of the desired student
  # @return [Stellar::Gradebook::Student] a student with the given name, or nil
  #     if no such student exists
  def named(name)
    @students.find { |a| a.name == name }
  end

  # A student in the course's Gradebook module.
  # @param [String] email the e-mail of the desired student
  # @return [Stellar::Gradebook::Student] a student with the given e-mail
  #     address, or nil if no such student exists
  def with_email(email)
    @students.find { |a| a.email == email }
  end
  
  # Reloads the contents of this student list.
  #
  # @return [Stellar::Gradebook::StudentList] self, for easy call chaining
  def reload!
    student_page = @client.get_nokogiri @url
    
    data_script = student_page.css('script').find do |script|
      /var rows\s*\=.*\;/m =~ script.inner_text
    end
    data = JSON.parse((/var rows\s*\=([^;]*)\;/m).
        match(data_script.inner_text)[1].gsub("'", '"'))
    
    @students = data.map { |student_line|
      email = student_line[0]
      url = URI.join @url.to_s, student_line[1]
      name = student_line[2].split(',', 2).map(&:strip).reverse.join(' ')
      
      begin
        Stellar::Gradebook::Student.new url, email, name, gradebook
      rescue ArgumentError
        nil
      end
    }.reject(&:nil?)
    
    self
  end
end  # class Stellar::Gradebook::StudentsList

# Stellar client scoped to a student's Gradebook page.
class Student
  # The student's full name.
  attr_reader :name
  
  # The student's e-mail.
  attr_reader :email

  # URL of the student's page of grades in the Gradebook.
  attr_reader :url
  
  # The course Gradebook that this student entry belongs to.
  attr_reader :gradebook
  
  # Generic Stellar client used to make requests.
  attr_reader :client
  
  # Creates a Stellar client scoped to a student's Gradebook page.
  #
  # @param [URI] url URL to the student's grade page
  # @param [Stellar::Gradebook] gradebook Stellar client scoped to the
  #     course gradebook containing this assignment
  def initialize(url, email, name, gradebook)
    @url = url
    @email = email
    @name = name
    @gradebook = gradebook
    @client = gradebook.client
    
    @grades = nil
    @input_names = nil
    @comment = nil
  end
  
  # The student's grades for all assignments.
  #
  # @return [Hash] map between assignment names and the student's scores
  def grades
    reload! unless @grades
    @grades
  end
  
  # The instructor's comment for the student.
  #
  # @return [String] the content of the comment
  def comment
    reload! unless @comment
    @comment
  end
  
  # Reloads the information in the student's grades page.
  #
  # @return [Stellar::Gradebook::Student] self, for easy call chaining
  def reload!
    page = @client.get_nokogiri @url

    @grades = {}
    @input_names = {} 
    page.css('.gradeTable tbody tr').each do |tr|
      name = tr.css('a[href*="assignment"]').inner_text
      input_field = tr.css('input[type="text"][name*=points]')
      @input_names[name] = input_field['name']
      @grades[name] = input_field['value'] && input_field['value'].to_f
    end
    @comment = page.css('textarea[name*="comment"]').inner_text
    
    self
  end
  
  # Changes some of the student's grades.
  #
  # @param [Hash] new_grades maps assignment names to the desired scores 
  # @return [Stellar::Gradebook::Student] self, for easy call chaining
  def update_grades(new_grades)
    reload! unless @input_names
    
    page = @client.get @url
    grade_form = page.form_with :action => /detail/i
    new_grades.each do |assignment_name, new_grade|
      unless input_name = @input_names[assignment_name]
        raise ArgumentError, "Invalid assignment #{assignment_name}"
      end
      grade_form.input_with(:name => input_name).value = new_grade.to_s
    end
    grade_form.submit grade_form.button_with(:class => /save/)
    
    reload!
  end
  
  # Changes the comment on the student's grades page.
  #
  # @param [String] text the new comment text
  # @return [Stellar::Gradebook::Student] self, for easy call chaining
  def update_comment(text)
    page = @client.get @url
    grade_form = page.form_with :action => /detail/i
    grade_form.textarea_with(:name => /comment/i).value = text
    grade_form.submit grade_form.button_with(:class => /save/)
    
    reload!
  end
end  # class Stellar::Gradebook::Assignment::Student

end  # class Stellar::Gradebook

end  # namespace Stellar
