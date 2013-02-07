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

  def print_q
    if @queue != []
    puts "ID".ljust(8) + " LAST NAME".ljust(12) + " FIRST NAME".ljust(12) +
    " EMAIL".ljust(35) + " ZIPCODE".ljust(12) + " CITY".ljust(10) +
    " STATE".ljust(10) + " ADDRESS".ljust(10) + " PHONE".ljust(10)
    end
    @queue.each do |person| 
      puts [person.id.to_s.ljust(8), person.last_name.to_s.ljust(12),
        person.first_name.to_s.ljust(12), person.email.to_s.ljust(35),
        person.zipcode.to_s.ljust(12), person.city.to_s.ljust(10), person.state.to_s.ljust(10),
        person.address.to_s.ljust(10), person.phone.to_s.ljust(10)].join(" ")
    end

  end

  def sort_q(attribute)
    @queue = @queue.sort {|attendee1, attendee2| attendee1.send(attribute.to_sym) <=> attendee2.send(attribute.to_sym)}
    print_q
  end

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