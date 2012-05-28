require "spec_helper"

describe Nginxtra::Actions::Start do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:compile_mock) { Object.new }
  let(:base_dir) { File.absolute_path File.expand_path("../..", __FILE__) }
  let(:config_file) { File.join(base_dir, ".nginx_conf") }
  let(:build_dir) { File.join(base_dir, "build/nginx") }
  let(:nginx_conf_dir) { File.join(build_dir, "conf") }
  let(:executable) { File.join(base_dir, "build/nginx/sbin/nginx") }
  let(:pidfile) { File.join(base_dir, ".nginx_pid") }

  it "compiles then starts nginx" do
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:config_contents).and_return("The config contents")
    File.should_receive(:write).with(config_file, "The config contents")
    thor_mock.stub(:inside).with(nginx_conf_dir).and_yield
    thor_mock.should_receive(:remove_file).with("nginx.conf")
    thor_mock.should_receive(:create_link).with("nginx.conf", config_file)
    thor_mock.should_receive(:run).with("start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{executable}")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_start_time, :fake_time)
    Nginxtra::Actions::Start.new(thor_mock, config_mock).start
  end
end
