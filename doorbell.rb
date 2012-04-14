require 'sinatra'
require 'json'

require 'net/http'
require 'uri'
require 'hpricot'
require 'date'

require 'config'

def get_events
  # get the events
  feed_uri = URI.parse(Config::FEED_URL)
  feed_uri.query = [feed_uri.query, "futureevents=true"].compact.join("&")
  data = Net::HTTP.get(feed_uri.host, feed_uri.path)
  # parse up the XML
  doc =  Hpricot::XML(data)
  events = []
  (doc/:entry).each do |entry|
    # get the event details
    event = {}
    event[:title] = (entry/"title")[0].inner_html
    event[:begin] = (entry/"gd:when")[0][:startTime]
    event[:end]   = (entry/"gd:when")[0][:endTime]
    event[:where] = (entry/"gd:where")[0][:valueString]
    # sanity check
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
    event[:begin] < DateTime.now and
      DateTime.now < event[:end] and
      /lounge/.match(event[:where].downcase)
  end
  return current
end

################################################################################

get '/' do
  # serve up an index.html
  redirect "/doorbell.html"
end

# AJAX endpoint, return JSON
# {current=? , upcoming=[]}
get '/check' do
  events = get_events
  current = current_events events

  if current then
    return {:current => current[0], :upcoming => [] }.to_json
  end

  return {:current => nil, :upcoming => [] }.to_json
end

# AJAX endpoint
get '/ring' do
  # rate limit
  # push out to twilio
end
