require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
#   if zipcode.nil?
#     zipcode = "00000"
#   elsif zipcode.length < 5
#     zipcode = zipcode.rjust 5, "0"
#   elsif zipcode.length > 5
#     zipcode = zipcode[0..4]
#   else
#     zipcode
#   end
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"
  
  begin 
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    rescue 
      "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter (id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!("-", "")
  phone_number.gsub!("(", "")
  phone_number.gsub!(")", "")
  phone_number.gsub!(".", "")
  phone_number.gsub!(" ", "")
  if phone_number.length < 10
    phone_number = "Invalid Phone Number"
  elsif phone_number.length == 11 && phone_number[0] == 1
    phone_number = phone_number[1..10]
  elsif phone_number.length == 10
    phone_number
  else
    phone_number = "Invalid Phone Number"
  end
end

puts "EventManager Initialized."
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  phone_number = clean_phone_number(row[:homephone])

  puts "#{name} #{zipcode} #{phone_number}"

end