require "ostruct"
require "cask/all"

module Bcu
  class Cask
    def initialize(cask)
      begin
        @cask = ::Cask.load_cask(cask)
      rescue ::Cask::CaskUnavailableError
        onoe "#{Tty.red}Cask \"#{cask}\" is not installed.#{Tty.reset}"

        @cask = OpenStruct.new
        @cask.name = [cask]
        @cask.token = cask
        @cask.version = nil
        @cask.auto_updates = false
        @cask.installed = false
      end
    end

    def cask
      @cask
    end

    def name
      cask.name.first
    end

    def token
      cask.token
    end

    def latest
      cask.version.to_s
    end

    def installed
      versions
    end

    def outdated?
      cask.instance_of?(::Cask::Cask) && !versions.include?(version)
    end

    def auto_updates
      cask.auto_updates
    end

    def installed?
      if cask.respond_to?(:installed)
        false
      else
        true
      end
    end

    private

    def versions
      @versions ||= ::Cask.installed_versions(token)
    end
  end
end
