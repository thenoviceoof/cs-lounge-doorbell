require 'sinatra'
require 'net/http'
require 'uri'
require 'hpricot'
require 'date'

require 'config'

get '/' do
  # get our current time
  t = Time.now.utc

  # get the events
  feed_uri = URI.parse(Config::FEED_URL)
  data = Net::HTTP.get(feed_uri.host, feed_uri.path)
  # parse up the XML
  doc =  Hpricot::XML(data)
  # go through each event, see if we're 
  current_events = []
  (doc/:entry).each do |entry|
    # get the event details
    event = {}
    (entry/"summary").inner_html.split("&lt;br&gt;").each do |s|
      s = s.strip
      if s
        key, *vals = s.split(":")
        if key
          key = key.downcase.sub(/\s/, '_')
          val = vals.join(":").strip
          event[key.intern] = val
        end
      end
    end
    # check the timing
    if (not event[:when]) then
      next
    end
    event[:when] = event[:when].sub("&amp;nbsp;\n", " ")
    event_when = event[:when].split(" ")
    event_b = event_when[1..4].join(" ").sub(/[.,]/,"")
    p event_b
    event[:begin] = DateTime.strptime(event_b, "%b %d %Y %I:%M%p")
    if event_when.length == 11 then
      # time to time over multiple days
      # time to time within a day
      # figure out the times
      event_e = (event_when[1..3] + event_when[6..6]).join(" ").sub(/[.,]/,"")
      event[:end] = DateTime.strptime(event_e, "%b %d %Y %I:%M%p")
    elsif event_when.length == 7
      # time to time within a day
      # figure out the times
      event_e = event_when[7..10].join(" ").sub(/[.,]/,"")
      event[:end] = DateTime.strptime(event_e, "%b %d %Y %I:%M%p")
    else
      # not interested in all day events
      next
    end
    # get the title
    event[:title] = (entry/"title").inner_html
    p event
  end
  "hello"
end
