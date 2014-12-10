RSpec.describe 'Logging::Appenders::Logstash' do
  before do
    FileUtils.rm_rf("/tmp/logstash.output")
    Timecop.freeze(Time.local(2014, 12, 10, 10, 20, 19))
    Logging.mdc.clear
  end

  let(:appender) {
    Logging::Appenders.logstash('logstash', :uri => "file:///tmp/logstash.output")
  }

  let(:logger) {
    log = Logging.logger['example_logger']
    log.add_appenders(appender)
    log.level = :info
    log
  }

  it "initializes via constructor Logging::Appenders.logstash" do
    expect(appender).to be_instance_of(Logging::Appenders::Logstash)
  end

  it "writes a log with a string" do
    logger.info("test")
    expect(log_content).to eq({"message" => "test",
                               "@timestamp" => "2014-12-10T10:20:19.000Z",
                               "@version" => "1",
                               "severity" => "INFO",
                               "host" => "pa-dev"})
  end

  it "writes a log with a hash" do
    logger.info("test" => 1, "test2" => "ok")
    expect(log_content).to eq({"@timestamp" => "2014-12-10T10:20:19.000Z",
                               "@version" => "1",
                               "severity" => "INFO",
                               "host" => "pa-dev",
                               "test" => 1,
                               "test2" => "ok"
                              })
  end

  it "enhances the information with the mdc context" do
    Logging.mdc["app"] = "core_api"
    logger.happy("test" => 1, "test2" => "ok")
    expect(log_content).to eq({"@timestamp" => "2014-12-10T10:20:19.000Z",
                               "@version" => "1",
                               "severity" => "HAPPY",
                               "host" => "pa-dev",
                               "test" => 1,
                               "test2" => "ok",
                               "app" => "core_api"
                              })
  end

  it "escapes multilines correctly" do
    logger.happy("test\ntest2")
    expect(File.readlines("/tmp/logstash.output").size).to eq(1)
  end


  def log_content
    JSON.parse(File.read("/tmp/logstash.output"))
  end
end