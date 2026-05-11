# frozen_string_literal: true

module Sigaffold
  class RbsIntroducer
    GITIGNORE_ENTRY = ".gem_rbs_collection"

    def initialize(path: Dir.pwd, confirmer: nil)
      @path = path
      @app_type = AppDetector.detect(path)
      @confirmer = confirmer
    end

    def run
      add_rbs_gem
      confirm_and_run("bundle install")
      confirm_and_run("bundle exec rbs collection init")
      add_gitignore_entry
      confirm_and_run("bundle exec rbs collection install")
    end

    private

    def add_rbs_gem
      if @app_type == :rails
        execute("bundle add rbs --skip-install --group development,test")
      else
        execute("bundle add rbs --skip-install")
      end
    end

    def add_gitignore_entry
      gitignore_path = File.join(@path, ".gitignore")

      if File.exist?(gitignore_path)
        content = File.read(gitignore_path)
        return if content.lines.any? { |line| line.chomp == GITIGNORE_ENTRY }
      end

      File.open(gitignore_path, "a") { |f| f.puts(GITIGNORE_ENTRY) }
    end

    def confirm_and_run(command)
      execute(command) if confirmed?(command)
    end

    def confirmed?(command)
      return @confirmer.call(command) if @confirmer

      interactive_confirm(command)
    end

    def interactive_confirm(command)
      print "Run `#{command}`? [y/N]: "
      $stdin.gets&.chomp&.downcase == "y"
    end

    def execute(command)
      system(command, chdir: @path)
    end
  end
end
