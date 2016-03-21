require "spec_helper"

describe Nginxtra::Actions::Start do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:compile_mock) { Object.new }
  let(:base_dir) { File.absolute_path File.expand_path("~/.nginxtra") }
  let(:nginx_conf_dir) { File.join(base_dir, "conf") }
  let(:executable) { File.join(base_dir, "nginx-#{Nginxtra::Config.nginx_version}/build/sbin/nginx") }
  let(:pidfile) { File.join(base_dir, ".nginx_pid") }

  it "compiles then starts nginx" do
    expect(Nginxtra::Actions::Compile).to receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    expect(compile_mock).to receive(:compile)
    expect(config_mock).to receive(:files).and_return(["nginx.conf", "mime_types.conf"])
    expect(config_mock).to receive(:file_contents).with("nginx.conf").at_least(:once).and_return("The nginx contents")
    expect(config_mock).to receive(:file_contents).with("mime_types.conf").at_least(:once).and_return("The mime_types contents")
    allow(thor_mock).to receive(:inside).with(nginx_conf_dir).and_yield
    expect(thor_mock).to receive(:create_file).with("nginx.conf", "The nginx contents", force: true)
    expect(thor_mock).to receive(:create_file).with("mime_types.conf", "The mime_types contents", force: true)
    expect(config_mock).to receive(:require_root?).and_return(false)
    expect(thor_mock).to receive(:run).with("start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{executable}") { RunMock.success }
    allow(thor_mock).to receive(:options).and_return({})
    expect(Nginxtra::Config).to receive(:nginx_running?).and_return(false)
    allow(Time).to receive(:now).and_return(:fake_time)
    expect(Nginxtra::Status).to receive(:[]=).with(:last_start_time, :fake_time)
    Nginxtra::Actions::Start.new(thor_mock, config_mock).start
  end

  it "throws an exception if nginx.conf is not specified" do
    expect(Nginxtra::Actions::Compile).to receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    expect(compile_mock).to receive(:compile)
    expect(config_mock).to receive(:files).and_return(["mime_types.conf"])
    allow(thor_mock).to receive(:options).and_return({})
    expect(Nginxtra::Config).to receive(:nginx_running?).and_return(false)
    expect { Nginxtra::Actions::Start.new(thor_mock, config_mock).start }.to raise_error(Nginxtra::Error::MissingNginxConfig)
  end
end
