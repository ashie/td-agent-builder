require_relative "../spec_helper"
require "rdkafka"
require "json"
require "bundler"

describe package("fluent-package") do
  it { should be_installed }
end

if os[:family] == 'redhat'
  describe user("fluentd") do
    it { should exist }
    it { should belong_to_group "fluentd" }
  end

  describe group("fluentd") do
    it { should exist }
  end
else
  describe user("_fluentd") do
    it { should exist }
    it { should belong_to_group "_fluentd" }
  end

  describe group("_fluentd") do
    it { should exist }
  end
end

describe "gem files" do
  lock_path = File.join(File.dirname(File.dirname(File.dirname(__FILE__))),
                        "fluent-package/Gemfile.lock")
  gem_path = File.join(File.dirname(lock_path),
                       File.basename(lock_path, ".lock"))
  Bundler::Definition.build(gem_path, lock_path, false).dependencies.each do |spec|
    if spec.should_include?
      describe package("#{spec.name}") do
        it { should be_installed.by('gem') }
      end
    end
  end
end

describe "rdkafka", :if => !centos8?(os) do
  it "can receive message via Rdkafka client" do
    config = {
      "bootstrap.servers": "localhost:9092",
      "group.id": "test"
    }
    consumer = Rdkafka::Config.new(config).consumer
    consumer.subscribe("test")

    wait_for_consumer_assignment(consumer)

    `echo "Hello, rdkafka" | /usr/bin/kafka-console-producer --broker-list localhost:9092 --topic test`

    message = consumer.each { |message| break message }
    expect(message.payload).to eq "Hello, rdkafka"
  end
end

describe "fluent-plugin-kafka", :if => !centos8?(os) do
  it "can receive message via fluent-plugin-kafka" do
    `echo "Hello, fluent-plugin-kafka" | /usr/bin/kafka-console-producer --broker-list localhost:9092 --topic test`
    Dir.glob("/tmp/log/td-agent/*.log") do |path|
      File.open(path) do |file|
        expect(JSON.parse(file.readlines.last)["message"]).to eq "Hello, fluent-plugin-kafka"
      end
    end
  end
end
