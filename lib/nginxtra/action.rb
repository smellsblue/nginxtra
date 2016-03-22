module Nginxtra
  module Action
    def initialize(thor, config)
      @thor = thor
      @config = config
    end

    # Run a daemon command to start or stop the nginx process.
    def daemon(action, additional_options = nil)
      action = "#{action} #{additional_options}" if additional_options
      run! "#{sudo}start-stop-daemon --#{action} --quiet --pidfile #{Nginxtra::Config.nginx_pidfile} --exec #{Nginxtra::Config.nginx_executable}"
    end

    private

    def run!(command)
      @thor.run command
      raise Nginxtra::Error::RunFailed, "The last run command failed" unless $?.success? # rubocop:disable Style/SpecialGlobalVars
    end

    def without_force
      Nginxtra::Action.ignore_force = true
      yield
    ensure
      Nginxtra::Action.ignore_force = false
    end

    def force?
      return false if Nginxtra::Action.ignore_force
      @thor.options["force"]
    end

    def interactive?
      !non_interactive?
    end

    def non_interactive?
      @thor.options["non-interactive"]
    end

    def sudo(force = false)
      "sudo " if (force || (@config && @config.require_root?)) && Process.uid != 0
    end

    class << self
      attr_accessor :ignore_force
    end
  end
end
