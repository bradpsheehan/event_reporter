###
# Event Reporter
# by Bradley Sheehan
# Completed 02/04/2013
###

require "csv"
require "sunlight"
require 'erb'
# require 'pry'
# require 'debugger'


Attendee = Struct.new(:id, :last_name, :first_name, :email, :zipcode, :city, :state, :address, :phone, :regdate)

class CommandPrompt

##############################################################  initialize  #############################################################

  def initialize
    @queue = []
    @attendees = []
  end

##############################################################  help  #############################################################

  def help(kind)
    @commands = {'load' => "the load command requires a filename", 'help' => "lists commands and their functions", 
                 'help command' => "requries lists function of a specific command",
                 'queue count' => "lists how many records are in the current queue", 'queue clear' => "emptys queue", 
                 'queue print' => "prints out a tab-delimited data table", 
                 'queue print by' => "prints the data table sorted by the specified <attribute> like zipcode", 
                 'queue save to' => "Export the current queue to the specified filename as a CSV", 
                 'find' => "Load the queue with all records matching the criteria for the given attribute"}

    if kind.empty?
      @commands.each {|command, description| puts "#{command}: #{description}" }
    else
     puts @commands[kind.join(" ")]
    end
  end

##############################################################  load  #############################################################

  def load(filename="event_attendees.csv")
    contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
    parse_contents(contents)
  end

  def parse_contents(contents)
    @attendees = []
    contents.each do |row|
      id = row[0]
      first_name = row[:first_name]
      last_name = row[:last_name]
      email = row[:email]
      zipcode = clean_zip(row[:zipcode])
      city = row[:city]
      state = row[:state]
      address = row[:address]
      homephone = clean_phone(row[:homephone])
      regdate = row[:regdate]

      attendee = Attendee.new(id, last_name, first_name, email, zipcode, city, state, address, homephone, regdate)

      @attendees << attendee
    end
  end

##############################################################  clean zip  #############################################################

  def clean_zip(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
  end

##############################################################  clean phone  #############################################################

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
##############################################################  queue  #############################################################

  def queue(input)
    # puts "You have entered the queue"

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
    puts "ID" + "LAST NAME"  +  "FIRST NAME"  +  "EMAIL"  +  "ZIPCODE" + "CITY" + "STATE" + "ADDRESS" + "PHONE"
    @queue.each do |person| 
      puts "#{person.id} #{person.last_name} #{person.first_name} #{person.email} #{person.zipcode} #{person.city} #{person.state} #{person.address} #{person.phone}"
    end

  end

  def sort_q(attribute)
    @queue = @queue.sort {|attendee1, attendee2| attendee1.send(attribute.to_sym) <=> attendee2.send(attribute.to_sym)}
    print_q
  end

##############################################################  find  #############################################################

  def find(attribute, criteria)    
    @queue = @attendees.select {|attendee| attendee.send(attribute).downcase == criteria.downcase}    
  end

##############################################################  run  #############################################################
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
        when 'help' then help
        when 'load' then load
        when 'queue' then queue(@parts[1..-1])
        when 'find' then find(@parts[1], @parts[2..-1].join)
          
        else puts "Sorry I don't know how to #{command}"
      end
    end
  end
end

command_prompt = CommandPrompt.new
command_prompt.run
