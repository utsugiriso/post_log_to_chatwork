require 'optparse'
require 'chatwork'
require 'filewatcher'

API_KEY = 'api_key'
ROOM_ID = 'room_id'
TO_IDS = 'to_ids'
LOG = 'log'
TO_PATTERN = 'to_pattern'
EXCLUDE = 'exclude'
INCLUDE = 'include'

params = ARGV.getopts('c:', "#{API_KEY}:", "#{ROOM_ID}:", "#{TO_IDS}:", "#{LOG}:", "#{TO_PATTERN}:", "#{EXCLUDE}:", "#{INCLUDE}:")
p params

ChatWork.api_key = params[API_KEY]

LINE_NUMBER_ORIGIN = 0
line_number = LINE_NUMBER_ORIGIN
if File.exist?(params[LOG])
  line_number = File.read(params[LOG]).count("\n")
end

FileWatcher.new([params[LOG]]).watch do |filename, event|
  if event != :delete && File.exist?(filename)
    File.open(filename) do |file|
      line_number = LINE_NUMBER_ORIGIN if File.read(params[LOG]).count("\n") < line_number
      is_to = false
      body = ''
      file.each_line do |line|
        if line_number < file.lineno && (params[EXCLUDE].nil? || !line.match(Regexp.new(params[EXCLUDE]))) && (params[INCLUDE].nil? || line.match(Regexp.new(params[INCLUDE])))
          body += "#{line}\n"
          is_to = true if !params[TO_PATTERN].nil? && !!line.match(params[TO_PATTERN])
          p "is_to:#{is_to}, line: #{line}"
        end
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
