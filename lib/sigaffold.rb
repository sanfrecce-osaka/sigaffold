# frozen_string_literal: true

require_relative "sigaffold/version"
require_relative "sigaffold/app_detector"
require_relative "sigaffold/rbs_introducer"
require_relative "sigaffold/repl_type_completor_introducer"
require_relative "sigaffold/rbs_trace_introducer"

module Sigaffold
  class Error < StandardError; end
end
