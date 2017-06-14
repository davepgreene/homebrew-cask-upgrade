$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "hbc"
require "extend/hbc"
require "bcu/options"

module Bcu
  def self.process(args)
    parse!(args)

    update if options.update
    # parse() has removed all flags from args
    options.casks = args.map { |a| get_cask(a) }

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

  def self.get_cask(cask_name)
    cask = Hbc.get_installed_cask(cask_name)

    if cask.nil?
      onoe "#{Tty.red}Cask \"#{cask_name}\" is not installed.#{Tty.reset}"
      return nil
    end

    {
      cask: cask,
      name: cask.to_s,
      full_name: cask.name.first,
      latest: cask.version.to_s,
      installed: Hbc.installed_versions(cask.to_s),
    }
  end

  def self.update
    result = Hbc::SystemCommand.run(HOMEBREW_BREW_FILE, args: ["update"], print_stderr: true, print_stdout: false)
    # This is brittle but will only need to change if
    # https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/update.sh#L579 changes
    ohai "Updated formulae" if result.success? && result.to_s.chomp != "Already up-to-date."
  end
end
