td_agent_config = File.expand_path(File.join(File.dirname(__FILE__), "../share/config"))
require td_agent_config
Dir.glob("#{ENV['TD_AGENT_TOPDIR'].gsub(/\\/, '/')}/lib/ruby/**/bundler/**/fluent/version.rb").each do |v|
  require v.delete_suffix(".rb")
end
puts "td-agent #{PACKAGE_VERSION} fluentd #{Fluent::VERSION} (#{FLUENTD_REVISION})"
