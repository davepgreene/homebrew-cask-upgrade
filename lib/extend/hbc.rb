CASKROOM = Hbc::Caskroom.path

module Hbc
  def self.load_cask(name)
    begin
      cask = CaskLoader.load(name)
    rescue NoMethodError
      cask = Hbc.load(name)
    end
    cask
  end

  def self.installed_apps
    Dir["#{CASKROOM}/*"].map { |e| File.basename e }
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(name)
    Dir["#{CASKROOM}/#{name}/*"].map { |e| File.basename e }
  end
end
