require File.expand_path("../../lib/nginxtra", __FILE__)

class RunMock
  class << self
    def success
      `true`
    end
  end
end

RSpec.configure do |config|
end
