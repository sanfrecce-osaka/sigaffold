# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup              # Install dependencies
bundle exec rake spec  # Run test suite (default: rake)
bin/console            # Interactive IRB session with gem loaded
bundle exec rake install   # Install gem locally
bundle exec rake release   # Release to RubyGems (creates git tag, pushes gem)
```

## Architecture

This is a Ruby gem (requires Ruby >= 3.2.0) at an early scaffolding stage.

- `lib/sigaffold.rb` — Main module entry point; defines `Sigaffold` module and `Sigaffold::Error` base error class
- `lib/sigaffold/version.rb` — Version constant; update here before releasing
- `sig/sigaffold.rbs` — RBS type signatures for Ruby 3.x type checking
- `spec/` — RSpec test suite; `.rspec` configures documentation format with color output
