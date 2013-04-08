#
# Cheap utility to DRY-up example code,
#   without relying on extra libraries.
#

module Kernel

  def require_on_install(gem_name)
    begin
      require gem_name
    rescue LoadError => e
      require 'rubygems'
      require 'rubygems/dependency_installer'
      STDERR.puts "Warning: #{gem_name} is not installed. Attempting an install..."
      Gem::DependencyInstaller.new({
        generate_rdoc: false,
        generate_ri:   false,
      }).install(gem_name)
      retry
    end
  end

end

