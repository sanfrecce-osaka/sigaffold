# frozen_string_literal: true

module Sigaffold
  class RbsTraceIntroducer
    DEFAULT_CONFIRMER = ->(command) {
      print "Run `#{command}`? [y/N]: "
      $stdin.gets&.chomp&.downcase
    }

    def initialize(path: Dir.pwd, confirmer: DEFAULT_CONFIRMER)
      @path = path
      @app_type = AppDetector.detect(path)
      @confirmer = confirmer
    end

    def run
      add_rbs_inline_gem
      add_rbs_trace_gem
      confirm_and_run("bundle install")
    end

    private

    def add_rbs_inline_gem
      if @app_type == :rails
        confirm_and_run("bundle add rbs-inline --skip-install --group development,test --require false")
      else
        confirm_and_run("bundle add rbs-inline --skip-install --require false")
      end
    end

    def add_rbs_trace_gem
      if @app_type == :rails
        confirm_and_run("bundle add rbs-trace --skip-install --group test")
      else
        confirm_and_run("bundle add rbs-trace --skip-install")
      end
    end

    def confirm_and_run(command)
      execute(command) if confirmed?(command)
    end

    def confirmed?(command)
      @confirmer.call(command) == "y"
    end

    def execute(command)
      system(command, chdir: @path)
    end
  end
end
