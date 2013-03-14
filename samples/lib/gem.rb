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
      Gem::DependencyInstaller.new({
        generate_rdoc: false,
        generate_ri:   false,
      }).install(g)
      retry
    end
  end

end

