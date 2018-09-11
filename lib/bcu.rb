$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "cask/all"
require "extend/hbc"
require "bcu/options"
require "bcu/cask"

module Bcu
  def self.process(args)
    parse!(args)

    update if options.update

    outdated, state = find_outdated_apps
    options.formatter.write(state)

    return if outdated.empty? || options.dry_run

    # Begin upgrading
    outdated.each do |app|
      ohai "Upgrading #{app.name} to #{app.latest}"

      # Clean up the cask metadata container.
      system "rm -rf #{app.cask.metadata_master_container_path}"

      # Force to install the latest version.
      system "brew cask install #{app.token} --force"

      # Remove the old versions.
      app.installed.each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app.token}/#{version}"
        end
      end
    end
  end

  def self.find_outdated_apps
    installed = if options.casks.empty?
                  ::Cask.installed_apps
                else
                  options.casks
                end

    outdated = []
    state = {}

    installed.map { |a| Cask.new(a) }.select(&:installed?).each do |app|
      if options.all && (app.latest == "latest")
        status = "#{Tty.red}latest but forced to upgrade#{Tty.reset}"
        outdated.push(app)
      elsif app.installed.include?(app.latest)
        status = "#{Tty.green}up to date#{Tty.reset}"
      else
        status = "#{Tty.red}#{app.installed.join(", ")}#{Tty.reset} -> #{Tty.green}#{app.latest}#{Tty.reset}"
        outdated.push(app)
      end

      state[app.name] = {
        :status => status,
        :cask => app
      }
    end

    [outdated, state]
  end

  def self.update
    result = SystemCommand.run(HOMEBREW_BREW_FILE, args: ["update"], print_stderr: true, print_stdout: false)
    # This is brittle but will only need to change if
    # https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/update.sh#L579 changes
    ohai "Updated formulae" if result.success? && result.to_s.chomp != "Already up-to-date."
  end
end
