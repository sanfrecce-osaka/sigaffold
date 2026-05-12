# frozen_string_literal: true

module Sigaffold
  class ReplTypeCompletorIntroducer
    DEFAULT_CONFIRMER = ->(command) {
      print "Run `#{command}`? [y/N]: "
      $stdin.gets&.chomp&.downcase
    }
    IRBRC_ENTRY = "IRB.conf[:COMPLETOR] = :type"

    def initialize(path: Dir.pwd, confirmer: DEFAULT_CONFIRMER)
      @path = path
      @app_type = AppDetector.detect(path)
      @confirmer = confirmer
    end

    def run
      add_repl_type_completor_gem
      confirm_and_run("bundle install")
      add_irbrc_entry
    end

    private

    def add_repl_type_completor_gem
      if @app_type == :rails
        confirm_and_run("bundle add repl_type_completor --skip-install --group development,test")
      else
        confirm_and_run("bundle add repl_type_completor --skip-install")
      end
    end

    def add_irbrc_entry
      irbrc_path = File.join(@path, ".irbrc")

      if File.exist?(irbrc_path)
        content = File.read(irbrc_path)
        return if content.lines.any? { |line| line.chomp == IRBRC_ENTRY }
      end

      File.open(irbrc_path, "a") { |f| f.puts(IRBRC_ENTRY) }
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
