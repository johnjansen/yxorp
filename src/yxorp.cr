require "./yxorp/*"

# module Yxorp
#   # TODO Put your code here
# end

# read the config and figure out what services to watch

require "http/client"
spawn do
  loop do
    # check each service for availability
    begin
      c = HTTP::Client.new("localhost", 8081)
      c.dns_timeout = 5
      c.connect_timeout = 5
      c.read_timeout = 5
      response = c.head("/")

      puts response.status_code
    rescue e : Errno
      if e.errno == Errno::ECONNREFUSED
        puts "OFFLINE"
      else
        puts e.inspect
      end
    end

    sleep 10
  end
end

require "http/server"
require "uri"
require "logger"
LOG = Logger.new(STDOUT)

server = HTTP::Server.new(8080) do |context|
  LOG.info context.request.resource

  c = HTTP::Client.new(URI.parse(context.request.resource))
  response = c.exec(context.request)
  unless response.content_type.nil?
    context.response.content_type = response.content_type.not_nil!
  end
  response.headers.each do |key, value|
    context.response.headers[key] = value
  end
  context.response.status_code = response.status_code
  context.response.print response.body
end

puts "Listening on http://127.0.0.1:8080"
server.listen(true)
