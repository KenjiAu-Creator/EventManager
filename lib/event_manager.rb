require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
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

def registration_by_hour(reg_date)
  date = Date._strptime(reg_date, "%m/%d/%Y %H:%M")

  if (defined?(@hour_registration) == nil)
    @hour_registration = Hash.new
  end

  if !@hour_registration.include? date[:hour]
    @hour_registration[date[:hour]] = 1
  else 
    @hour_registration[date[:hour]] += 1
  end

end

def registration_by_day(reg_date)
  #day of the week is returned. Sunday is 0

  date = Date._strptime(reg_date, "%m/%d/%Y %H:%M")
  date_format = Date.parse("#{date[:year]}-#{date[:mon]}-#{date[:mday]}")

  if (defined?(@week_registration) == nil)
    # @week_registration = Hash.new
    @week_registration = {
      "Sunday" => 0,
      "Monday" => 0,
      "Tuesday" => 0,
      "Wednesday" => 0,
      "Thursday" =>0,
      "Friday" => 0, 
      "Saturday" => 0,
    }
    @week_map = {
      0 => "Sunday",
      1 => "Monday",
      2 => "Tuesday",
      3 => "Wednesday",
      4 => "Thursday",
      5 => "Friday",
      6 => "Saturday",
    }
  end

  @week_registration[@week_map[date_format.wday]] += 1
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

  
  registration_by_hour(row[:regdate])

  registration_by_day(row[:regdate])

  
end

@hour_registration.values.sort.reverse!
puts "Top three hours for registration are:"
print @hour_registration.keys[0..2]
puts "\nTop day of the week for registration is:"
@week_registration.values.sort.reverse!
puts @week_registration.keys[0]