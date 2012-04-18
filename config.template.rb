# configuration of the doorbell

module Config
  # gcal things
  # feed: use private/full
  FEED_URL = ""

  # twilio things
  TWILIO_SID = ""
  TWILIO_AUTH_TOKEN = ""
  TWILIO_NUMBER = "" # from

  # email -> number (for texts)
  TWILIO_TARGET = {"guy@example.com" => "+1234567890"}

  MESSAGE = "Someone rang the doorbell!"
end
