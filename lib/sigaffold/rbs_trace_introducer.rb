# frozen_string_literal: true

require "prism"

module Sigaffold
  class RbsTraceIntroducer
    DEFAULT_CONFIRMER = ->(command) {
      print "Run `#{command}`? [y/N]: "
      $stdin.gets&.chomp&.downcase
    }
    RbsTraceConfig = <<~CONFIG
      if ENV.fetch('TRACE', '') in /\\A.+/ => path_glob_or_flag
        require "rbs/trace"
        options = (path_glob_or_flag in %r{\\A/.+} => path_glob) ? { paths: Dir.glob("#\{Dir.pwd}#\{path_glob}") } : {} # rubocop:disable Style/RedundantParentheses
        trace = RBS::Trace.new(**options)
        trace.add_generics_size!(
          'CSV::Table' => 1, 'ActiveSupport::HashWithIndifferentAccess' => 2, 'ActionController::ParameterMissing' => 2
        )

        config.before(:suite) { trace.enable }
        config.after(:suite) do
          trace.disable
          trace.save_comments(:rbs_colon)
          out_dir = "tmp/sig-#\{ENV.fetch('TEST_ENV_NUMBER'}', '0')}"
          warn "[RBS_TRACE] saving to #\{out_dir}"
          trace.save_files(out_dir:)
          warn '[RBS_TRACE] saved'
        end
      end
    CONFIG

    def initialize(path: Dir.pwd, confirmer: DEFAULT_CONFIRMER)
      @path = path
      @app_type = AppDetector.detect(path)
      @confirmer = confirmer
    end

    def run
      add_rbs_trace_gem
      confirm_and_run("bundle install")
      add_rbs_trace_config
    end

    private

    def add_rbs_trace_gem
      if @app_type == :rails
        confirm_and_run("bundle add rbs-trace --skip-install --group test")
      else
        confirm_and_run("bundle add rbs-trace --skip-install")
      end
    end

    def add_rbs_trace_config
      config_file_path = rspec_config_file_path
      return unless File.exist?(config_file_path)

      source = File.read(config_file_path)
      return if source.include?("RBS::Trace")

      result = Prism.parse(source)
      block_node = find_rspec_configure_block(result.value)
      return unless block_node

      closing_offset = block_node.closing_loc.start_offset
      indent = block_node.closing_loc.start_column + 2
      indented_config = indent_each_line(RbsTraceConfig, indent)
      separator = block_node.body ? "\n" : ""

      File.write(config_file_path, source[0...closing_offset] + separator + indented_config + source[closing_offset..])
    end

    def rspec_config_file_path
      filename = @app_type == :rails ? "spec/rails_helper.rb" : "spec/spec_helper.rb"
      File.join(@path, filename)
    end

    def find_rspec_configure_block(node)
      return nil unless node

      if node.is_a?(Prism::CallNode) &&
          node.name == :configure &&
          node.receiver&.is_a?(Prism::ConstantReadNode) &&
          node.receiver.name == :RSpec &&
          node.block.is_a?(Prism::BlockNode)
        return node.block
      end

      node.child_nodes.compact.each do |child|
        result = find_rspec_configure_block(child)
        return result if result
      end

      nil
    end

    def indent_each_line(text, spaces)
      prefix = " " * spaces
      text.each_line.map { |line|
        line.chomp.empty? ? "\n" : "#{prefix}#{line}"
      }.join
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
