require 'sinatra'
require 'net/http'
require 'uri'
require 'hpricot'
require 'date'

require 'config'

get '/' do
  # get the events
  # get events today
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

  # check if we match the criteria
  current = events.find_all do |event|
    # critera for putting up a doorbell
    event[:begin] < DateTime.now and
      DateTime.now < event[:end] and
      /lounge/.match(event[:where].downcase)
  end

  # 
  if current then
    return "Event RIGHT NOW"
  end

  return "No event right now"
end
