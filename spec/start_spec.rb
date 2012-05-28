require "spec_helper"

describe Nginxtra::Actions::Start do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:compile_mock) { Object.new }
  let(:base_dir) { File.absolute_path File.expand_path("../..", __FILE__) }
  let(:config_file) { File.join(base_dir, "conf/nginx.conf") }
  let(:mime_file) { File.join(base_dir, "conf/mime_types.conf") }
  let(:build_dir) { File.join(base_dir, "build/nginx") }
  let(:nginx_conf_dir) { File.join(build_dir, "conf") }
  let(:executable) { File.join(base_dir, "build/nginx/sbin/nginx") }
  let(:pidfile) { File.join(base_dir, ".nginx_pid") }

  it "compiles then starts nginx" do
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:files).and_return(["nginx.conf", "mime_types.conf"])
    config_mock.should_receive(:file_contents).with("nginx.conf").and_return("The nginx contents")
    config_mock.should_receive(:file_contents).with("mime_types.conf").and_return("The mime_types contents")
    File.should_receive(:write).with(config_file, "The nginx contents")
    File.should_receive(:write).with(mime_file, "The mime_types contents")
    thor_mock.should_receive(:run).with("start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{executable}")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_start_time, :fake_time)
    Nginxtra::Actions::Start.new(thor_mock, config_mock).start
  end

  it "throws an exception if nginx.conf is not specified"
end
