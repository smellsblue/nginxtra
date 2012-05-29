module Nginxtra
  module Action
    def initialize(thor, config, options = {})
      @thor = thor
      @config = config
      @options = options
    end
  end
end
