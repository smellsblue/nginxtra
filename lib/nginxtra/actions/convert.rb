module Nginxtra
  module Actions
    class Convert
      include Nginxtra::Action

      def convert
        @thor.say "Coming soon...", :yellow
      end
    end
  end
end
