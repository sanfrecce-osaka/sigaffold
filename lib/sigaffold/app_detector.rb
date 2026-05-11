# frozen_string_literal: true

module Sigaffold
  module AppDetector
    def self.detect(path = Dir.pwd)
      return :gem if gem?(path)
      return :rails if rails?(path)

      :other
    end

    class << self
      private

      def gem?(path)
        Dir.glob(File.join(path, "*.gemspec")).any?
      end

      def rails?(path)
        app_rb = File.join(path, "config", "application.rb")
        File.exist?(app_rb) && File.read(app_rb).include?("Rails::Application")
      end
    end
  end
end
