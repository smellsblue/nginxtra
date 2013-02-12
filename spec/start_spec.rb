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
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:files).and_return(["nginx.conf", "mime_types.conf"])
    config_mock.should_receive(:file_contents).with("nginx.conf").at_least(:once).and_return("The nginx contents")
    config_mock.should_receive(:file_contents).with("mime_types.conf").at_least(:once).and_return("The mime_types contents")
    thor_mock.stub(:inside).with(nginx_conf_dir).and_yield
    thor_mock.should_receive(:create_file).with("nginx.conf", "The nginx contents", :force => true)
    thor_mock.should_receive(:create_file).with("mime_types.conf", "The mime_types contents", :force => true)
    config_mock.should_receive(:require_root?).and_return(false)
    thor_mock.should_receive(:run).with("start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{executable}") { RunMock.success }
    thor_mock.stub(:options).and_return({})
    Nginxtra::Config.should_receive(:nginx_running?).and_return(false)
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_start_time, :fake_time)
    Nginxtra::Actions::Start.new(thor_mock, config_mock).start
  end

  it "throws an exception if nginx.conf is not specified" do
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:files).and_return(["mime_types.conf"])
    thor_mock.stub(:options).and_return({})
    Nginxtra::Config.should_receive(:nginx_running?).and_return(false)
    lambda { Nginxtra::Actions::Start.new(thor_mock, config_mock).start }.should raise_error(Nginxtra::Error::InvalidConfig)
  end
end
