require 'fileutils'
require "win32/service"
require "win32/registry"
require "optparse"
include Win32

install_dir = "#{ARGV[0]}"

default_fluentdwinsvc = "-c '#{install_dir}etc\\fluent\\fluentd.conf' -o '#{install_dir}fluentd.log'"
registry_key = "SYSTEM\\CurrentControlSet\\Services\\fluentdwinsvc"

puts("fluentdwinsvc default: #{default_fluentdwinsvc}")
begin
  Win32::Registry::HKEY_LOCAL_MACHINE.open(registry_key, Win32::Registry::KEY_ALL_ACCESS) do |reg|
    # Check whether RegValue exists or not
    puts("fluentdwinsvc registry key was opened: #{registry_key}")
    begin
      previous_fluentdopt = reg['fluentdopt', Win32::Registry::REG_SZ]
      puts("fluentdwinsvc current value: #{previous_fluentdopt}")
      if previous_fluentdopt != default_fluentdwinsvc
        puts("fluentdwinsvc: fluentdopt configuration was kept because option was changed from default")
      else
        puts("fluentdwinsvc: fluentdopt configuration was same as default one: #{default_fluentdwinsvc}")
      end
    rescue Win32::Registry::Error
      # As fluentdopt value does not exist, then set default configuration
      puts("fluentdwinsvc: reset to default fluentdopt configuration")
      reg['fluentdopt', Win32::Registry::REG_SZ] = default_fluentdwinsvc
    end
  end
rescue Win32::Registry::Error
  # No fluentdwinsvc key yet.
  puts("fluentdwinsvc: create #{registory_key} and set default fluentdopt configuration")
  Win32::Registry::HKEY_LOCAL_MACHINE.create(registory_key, Win32::Registry::KEY_ALL_ACCESS) do |reg|
    reg['fluentdopt', Win32::Registry::REG_SZ] = default_fluentdwinsvc
  end
end
