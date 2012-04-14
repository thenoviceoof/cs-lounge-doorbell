require 'sinatra'
require 'net/http'
require 'uri'
require 'xml'

require 'config'

get '/' do
  # get our current time
  t = Time.now.utc

  # get the events
  feed_uri = URI.parse(Config::FEED_URL)
  data = Net::HTTP.get(feed_uri.host, feed_uri.path)
  # parse up the XML
  
  # go through each event, see if we're 
  
end
