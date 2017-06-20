require "optparse"
require "ostruct"
require_relative "./formatter"

module Bcu
  class << self
    attr_accessor :options
  end

  def self.parse!(args)
    options = OpenStruct.new

    options.casks = []
    options.all = false
    options.cleanup = false
    options.force = false
    options.dry_run = false
    options.update = false
    options.formatter = VerticalFormatter.new

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [CASK] [options]"

      opts.on("-a", "--all", "Force upgrade outdated apps including the ones marked as latest") do
        options.all = true
      end

      opts.on("-c", "--cleanup", "Cleans up cached downloads and tracker symlinks after updating") do
        options.cleanup = true
      end

      opts.on("-f", "--force", "Include apps that are marked as latest (i.e. force-reinstall them)") do
        options.force = true
      end

      opts.on("--dry-run", "Print outdated apps without upgrading them") do
        options.dry_run = true
      end

      opts.on("--format FORMAT", "Choose how the printed output is formatted: [table, vertical (default)]") do |format|
        options.formatter = case format.downcase
                            when 'table'
                              TableFormatter.new
                            when 'vertical'
                              VerticalFormatter.new
                            end
      end

      opts.on("--update", "Update Homebrew, taps, and formulae before checking outdated casks") do
        options.update = true
      end
    end

    parser.parse!(args)

    options.casks = args

    self.options = options
  end
end
