require "date"
require "rsnapshot_backups/rsnapshot_helper.rb"
include ActionView::Helpers::DateHelper

class RsnapshotLogUtil
	class << self
		def parse_datetime_string(string)
			parsed = DateTime.parse(string).strftime('%a, %d %b %Y %H:%M:%S')
			ago_duration = time_ago_in_words(parsed).capitalize
			parsed + " (#{ago_duration} ago)"
		end

		def get_log_file_path
			"/var/log/rsnapshot.log"
		end

		def get_sample_log_file_path
			Rails.root+Dir["plugins/*rsnapshot_backups/db/sample-data/sample-rsnapshot-log"][0]
		end

		def parse_log_file
			log_enteries = []
			return log_enteries unless File.exists?(get_log_file_path)

			File.open(get_log_file_path, "r").each do |line|
				if line =~ /\[.*\] \/bin\/rsnapshot (daily|weekly|monthly): .*/

					unless line.index("started").blank?
						type = nil
						start_message = nil
						if !(line.index("daily").nil?)
							type = "daily"
							start_message = line[44..-1].strip
						elsif !(line.index("weekly").nil?)
							type = "weekly"
							start_message = line[45..-1].strip
						elsif !(line.index("monthly").nil?)
							type = "monthly"
							start_message = line[46..-1].strip
						end

						log_enteries << {start_time: parse_datetime_string(line[1..19]), type: type, 
							start_message: start_message}
					else
						end_message = nil
						if !(line.index("daily").nil?)
							end_message = line[44..-1].strip
						elsif !(line.index("weekly").nil?)
							end_message = line[45..-1].strip
						elsif !(line.index("monthly").nil?)
							end_message = line[46..-1].strip
						end

						last_entry = log_enteries.last
						last_entry[:end_time] = parse_datetime_string(line[1..19])
						last_entry[:end_message] = end_message
						log_enteries.pop()
						log_enteries << last_entry
					end
				end

			end
			log_enteries
		end

		def get_log_output
			log_enteries = self.parse_log_file
			return log_enteries.reverse
		end

	end
end
