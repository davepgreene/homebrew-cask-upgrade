$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "hbc"
require "extend/hbc"
require "optparse"
require "ostruct"

module Bcu
  def self.parse(args)
    options = OpenStruct.new
    options.all = false
    options.cask = nil

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [options]"

      opts.on("-a", "--all", "Force upgrade outdated apps including the ones marked as latest") do
        options.all = true
      end

      opts.on("--dry-run", "Print outdated apps without upgrading them") do
        options.dry_run = true
      end

      opts.on("--cask [CASK]", "Specify a single cask for upgrade") do |cask_name|
        Hbc.each_installed(true) do |app|
          options.cask = app if cask_name == app[:name]
        end

        if options.cask.nil?
          onoe "#{Tty.red}Cask \"#{cask_name}\" is not installed.#{Tty.reset}"
          exit(1)
        end
      end

      # `-h` is not available since the Homebrew hijacks it.
      opts.on_tail("--h", "Show this message") do
        puts opts
        exit
      end
    end

    parser.parse!(args)
    options
  end

  def self.process(args)
    options = parse(args)
    result = Hbc::SystemCommand.run(HOMEBREW_BREW_FILE, args: ["update"], print_stderr: true, print_stdout: false)
    # This is brittle but will only need to change if
    # https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/update.sh#L579 changes
    if result.success? && result.to_s.chomp != "Already up-to-date."
      puts "Updated formulae"
    end

    Hbc.outdated(options).each do |app|
      next if options.dry_run

      ohai "Upgrading #{app[:name]} to #{app[:latest]}"

      # Clean up the cask metadata container.
      system "rm -rf #{app[:cask].metadata_master_container_path}"

      # Force to install the latest version.
      system "brew cask install #{app[:name]} --force"

      # Remove the old versions.
      app[:installed].each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app[:name]}/#{version}"
        end
      end
    end
  end
end
