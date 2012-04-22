require 'sinatra'
require 'json'

require 'net/http'
require 'uri'
require 'hpricot'
require 'date'

require 'twilio-ruby'

require 'config'

def get_events
  # get the events
  feed_uri = URI.parse(Config::FEED_URL)
  feed_uri.query = [feed_uri.query, "futureevents=true"].compact.join("&")
  data = Net::HTTP.get(feed_uri.host, feed_uri.path)
  data = Net::HTTP.get(feed_uri)
  # parse up the XML
  doc =  Hpricot::XML(data)
  events = []
  (doc/:entry).each do |entry|
    # check that we have requisite fields
    title = (entry/"title")[0]
    time = (entry/"gd:when")[0]
    location = (entry/"gd:where")[0]
    email = ((entry/"author")/"email")[0]
    # !!! get the url
    # element sanity check
    if not(title and time and location and email)
      next
    end
    # get the event details
    event = {}
    event[:title] = title.inner_html
    event[:begin] = time[:startTime]
    event[:end]   = time[:endTime]
    event[:where] = location[:valueString]
    event[:who]   = email.inner_html
    # another sanity check
    if not event[:begin] or not event[:end] then
      next
    end
    # check the timing
    event[:begin] = DateTime.strptime(event[:begin], "%Y-%m-%dT%H:%M:%S.000%z")
    event[:end]   = DateTime.strptime(event[:end], "%Y-%m-%dT%H:%M:%S.000%z")
    # and stick on the end
    events << event
  end
  return events
end

def current_events events
  # check if we match the criteria
  current = events.find_all do |event|
    # critera for putting up a doorbell
    # put up the doorbell 15 minutes in advance
    (event[:begin] - 15.0/1440) < DateTime.now and
      DateTime.now < event[:end] and
      /lounge/.match(event[:where].downcase) != nil
  end
  return current
end

# partial time printer
def print_time t
  # within a week, print the weekday/hour
  # within a month, print the month/day/hour
  # month (31 days) later, print month/day
  if t < DateTime.now then
    return "Passed"
  elsif t < DateTime.now + 7 then
    return t.strftime "%a, %k:%M"
  elsif t < DateTime.now + 31 then
    return t.strftime "%b %e %k:%M"
  else
    return t.strftime "%b %e"
  end
end

################################################################################

get '/' do
  # serve up an index.html
  events = get_events
  current = (current_events events)[0]
  # resort, exclude current
  events = (Set.new(events) - Set.new([current])).to_a
  events.sort! { |a,b| a[:begin] <=> b[:begin] }
  # check if there's someone to ring
  if current
    number = Config::TWILIO_TARGET[current[:who]]
    # make sure there's a mapping
    if number == nil then
      current = false
    end
  end
  erb :doorbell, :locals => {:current => current, :events => events}
end

# AJAX endpoint
get '/ring' do
  # rate limit
  # check if it's actually an event
  events = get_events
  current = (current_events events)[0]
  if current then
    number = Config::TWILIO_TARGET[current[:who]]
    # make sure there's a mapping
    if number == nil then
      return {:ring => false, :current => true}.to_json
    end

    # # push out to twilio
    # # set up a client to talk to the Twilio REST API
    # @client = Twilio::REST::Client.new(Config::TWILIO_SID,
    #                                    Config::TWILIO_AUTH_TOKEN)
    # # and send the sms
    # @client.account.sms.messages.create(:from => Config::TWILIO_NUMBER,
    #                                     :to => number
    #                                     :body => Config::MESSAGE)

    # make sure it worked
    # ???
    return {:ring => true, :current => true}.to_json
  else
    return {:ring => false, :current => false}.to_json
  end
end
