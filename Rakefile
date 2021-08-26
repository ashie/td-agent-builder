#!/usr/bin/env rake
#
# fluent-package-builder
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

PACKAGES = [
  "td-agent",
]
FLUENTD_PACKAGES = [
  "fluentd",
]

APT_SOURCE_PACKAGES = [
  "td-agent-apt-source"
]
FLUENTD_APT_SOURCE_PACKAGES = [
  "fluentd-apt-source"
]

ALL_PACKAGE = [
  "td-agent",
  "td-agent-apt-source",
  "fluentd",
  "fluentd-apt-source",
]

def define_bulked_task(name, description, packages = PACKAGES)
  desc description
  task name.to_sym do
    packages.each do |package|
      cd(package) do
        # e.g. apt:fluentd_build => apt:build
        prefixed_target = name.split(':', 2).last
        if prefixed_target.start_with?("fluentd_")
          ruby("-S", "rake", name.sub(/:fluentd_/, ':').to_s)
        else
          ruby("-S", "rake", name.to_s)
        end
      end
    end
  end
end

[
  ["clean",            "Remove any temporary products", ALL_PACKAGE],
  ["clobber",          "Remove any generated files", ALL_PACKAGE],
  ["build:deb_config", "Create configuration files for Debian like systems"],
  ["build:rpm_config", "Create configuration files for Red Hat like systems with systemd"],
  ["build:rpm_old_config", "Create configuration files for Red Hat like systems without systemd"],
  ["build:all",        "Install all components"],
  ["apt:build",        "Build deb packages"],
  ["apt:fluentd_build","Build fluentd deb packages", FLUENTD_PACKAGES],
  ["yum:build",        "Build RPM packages"],
  ["yum:fluentd_build","Build fluentd RPM packages", FLUENTD_PACKAGES],
  ["msi:build",        "Build MSI package (alias for msi:dockerbuild)"],
  ["msi:fluentd_build","Build fluentd MSI package (alias for msi:dockerbuild)", FLUENTD_PACKAGES],
  ["msi:selfbuild",    "Build MSI package without using Docker"],
  ["msi:dockerbuild",  "Build MSI package by Docker"],
  ["dmg:selfbuild",    "Build macOS package without using Docker"],
].each do |params|
  define_bulked_task(*params)
end

[
  ["apt:build", "Build td-agent-apt-source deb packages", APT_SOURCE_PACKAGES],
  ["apt:fluentd_build", "Build fluentd-apt-source deb packages", FLUENTD_APT_SOURCE_PACKAGES],
].each do |params|
  define_bulked_task(*params)
end

if ENV["INSTALLATION_TEST"]
  require "rspec/core/rake_task"
  namespace :serverspec do
    desc "Run serverspec on linux"
    RSpec::Core::RakeTask.new(:linux)  do |t|
      t.pattern = "serverspec/linux/*.rb"
    end

    desc "Run serverspec on windows"
    RSpec::Core::RakeTask.new(:windows)  do |t|
      t.pattern = "serverspec/windows/*.rb"
    end
  end
end
