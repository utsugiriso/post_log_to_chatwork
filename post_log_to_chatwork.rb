require 'optparse'
require 'chatwork'
require 'filewatcher'

API_KEY = 'api_key'
ROOM_ID = 'room_id'
TO_IDS = 'to_ids'
LOG = 'log'
TO_PATTERN = 'to_pattern'

params = ARGV.getopts('c:', "#{API_KEY}:", "#{ROOM_ID}:", "#{TO_IDS}:", "#{LOG}:", "#{TO_PATTERN}:")
p params

ChatWork.api_key = params[API_KEY]

LINE_NUMBER_ORIGIN = -1
line_number = LINE_NUMBER_ORIGIN
if File.exist?(params[LOG])
  File.open(params[LOG]) do |file|
    line_number = file.lineno
  end
end

FileWatcher.new([params[LOG]]).watch do |filename, event|
  if event != :delete && File.exist?(filename)
    File.open(filename) do |file|
      line_number = LINE_NUMBER_ORIGIN if file.lineno < line_number
      index = 0
      is_to = false
      body = ''
      file.each_line do |line|
        if line_number < index
          body += "#{line}\n"
          is_to = true if !params[TO_PATTERN].nil? && line.include?(params[TO_PATTERN])
        end
        index += 1
      end
      line_number = file.lineno
      if body.length != 0
        body.chop!
        body = "#{params[TO_IDS].split(',').map{|to_id| "[TO:#{to_id}]"}.join}\n#{body}" if is_to
        ChatWork::Message.create(room_id: params[ROOM_ID], body: body)
      end
    end
  end
end