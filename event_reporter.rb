###
# Event Reporter
# by Bradley Sheehan
# Completed 02/04/2013
###

require "csv"
require "sunlight"
require 'erb'

Attendee = Struct.new(:id, :last_name, :first_name, :email, :zipcode, :city, :state, :address, :phone, :regdate)

class CommandPrompt

  def initialize
    @queue = []
    @attendees = []
  end

  def help(kind)
    @commands = {'load' => "The load command requires a filename", 'help' => "lists commands and their functions", 
                 'help command' => "Requries lists function of a specific command",
                 'queue count' => "Lists how many records are in the current queue", 'queue clear' => "emptys queue", 
                 'queue print' => "Prints out a tab-delimited data table", 
                 'queue print by' => "Prints the data table sorted by the specified <attribute> (e.g. zipcode)", 
                 'queue save to' => "Export the current queue to the specified filename as a CSV", 
                 'find' => "Load the queue with all records matching the criteria for the given attribute"}

    if kind.empty?
      @commands.each {|command, description| puts "#{command}: #{description}" }
    else
     puts @commands[kind.join(" ")]
    end
  end

  def load(filename)
    if filename.nil?
      filename = "event_attendees.csv"
    end
    contents = CSV.open(filename, headers: true, header_converters: :symbol)
    parse_contents(contents)
  end

  def parse_contents(contents)
    @attendees = []
    contents.each do |row|
      id = row[0] || ""
      first_name = row[:first_name] || ""
      last_name = row[:last_name] || ""
      email = row[:email_address] || ""
      zipcode = clean_zip(row[:zipcode]) || ""
      city = row[:city] || ""
      state = row[:state] || ""
      address = row[:street]
      homephone = clean_phone(row[:homephone]) || ""
      regdate = row[:regdate] || ""

      attendee = Attendee.new(id, last_name, first_name, email, zipcode, city, state, address, homephone, regdate)

      @attendees << attendee
    end
  end

  def clean_zip(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
  end

  def clean_phone(homephone)
        phone = homephone.to_s.gsub(/[-.()]/, '').split(" ").join

        if phone.length < 10 
          phone = ".........."
        elsif     
          phone.length == 10
          phone = phone
        elsif phone.length > 11
          phone = ".........."  
        elsif (phone.length) == 11 && (phone.start_with?(1))
          phone = phone[1..10]
        else
          phone = ".........."
        end
    end

  def queue(input)
    case input[0]
      when 'count' then puts @queue.size
      when 'clear' then @queue.clear
      when 'print' 
        if input[-1] == 'print'
          print_q
        else
        sort_q(input[-1].to_s)
        end
      when 'save' then save_to(input[2])
    end
  end

  def save_to(filename)
    @results = []
    header = ["ID", "LAST NAME", "FIRST NAME", "EMAIL", "ZIPCODE", "CITY", "STATE", "ADDRESS", "PHONE"]
    CSV.open("#{filename}", "w") do |file|
      file << header
      @queue.each do |person|
        @results << person.id << person.last_name << person.first_name << person.email << person.zipcode << person.city << person.state << person.address << person.phone
        file << @results
        @results = []
      end
    end
  end

############################################### table & print ###########################################
  def gutter
    8
  end

  def fields
    %w{id last_name first_name email zipcode city state address phone}
  end

  def column_widths(fields)
    widths = {}
    fields.each do |field|
      widths[field.downcase] = longest_value(field.downcase) + gutter
    end
    widths
  end

  def longest_value(field)
    value = []
    @queue.each do |person|
    value << person[field].length
      end
      value.max
  end

  def print_header(column_widths)
    puts "\n"
    puts "-"*155
    # puts column_widths.class
    print "ID".ljust(column_widths["id"])
    print "LAST NAME".ljust(column_widths["last_name"])
    print "FIRST NAME".ljust(column_widths["first_name"])
    print " EMAIL".ljust(column_widths["email"])
    print "ZIPCODE".ljust(column_widths["zipcode"])
    print "CITY".ljust(column_widths["city"])
    print "STATE".ljust(column_widths["state"])
    print "ADDRESS".ljust(column_widths["address"])
    print "PHONE".ljust(column_widths["phone"])
    puts "-"*155
    puts "\n"
  end

  def print_person(person, column_widths)
    puts [ 
    person.id.ljust(column_widths["id"]),
    person.last_name.ljust(column_widths["last_name"]),
    person.first_name.ljust(column_widths["last_name"]),
    person.email.ljust(column_widths["email"]),
    person.zipcode.ljust(column_widths["zipcode"]),
    person.city.ljust(column_widths["city"]),
    person.state.ljust(column_widths["state"]),
    person.address.ljust(column_widths["address"]),
    person.phone.ljust(column_widths["phone"])
    ].join(" ")
  end

  def sort_q(attribute)
    @queue = @queue.sort {|attendee1, attendee2| attendee1.send(attribute.to_sym) <=> attendee2.send(attribute.to_sym)}
    print_q
  end

  def print_q
    column_widths = column_widths(fields)
    print_header(column_widths)
    @queue.each do |person|
      print_person(person, column_widths)
    end
  end

  # def print_q
  #   column_widths = column_widths(fields)
  #   print_header(column_widths)
  #   count = 0
  #   q_size = @queue.size
  #   @queue.each do |person|
  #     if (count != 0) && (count % 10 == 0)
  #       puts "Displaying records #{count - 10} - #{count} of #{q_size}"
  #       input = ""
  #       while input != "\n"
  #         puts "press space bar or the enter key to show the next set of records"
  #         input = gets
  #         end
  #       end
  #     print_person
  #   end
  # end

  ###############################################

  def find(attribute, criteria)    
    @queue = @attendees.select {|attendee| attendee.send(attribute).downcase == criteria.downcase}    
  end

  def run
    puts "Welcome to Event Reporter"
    command = ""
    while command != "q"
      printf "enter command: "

      input = gets.chomp
      @parts = input.split(" ")

      command = @parts[0]

      case command
        when 'q' then puts "Goodbye!"
        when 'help' then help(@parts[1..-1])
        when 'load' then load(@parts[1])
        when 'queue' then queue(@parts[1..-1])
        when 'find' then find(@parts[1], @parts[2..-1].join(" "))
          
        else puts "Sorry I don't know how to #{command}"
      end
    end
  end
end

command_prompt = CommandPrompt.new
command_prompt.run