# This file serves as a mock module for Jekyll to allow testing of the
# plugin without requiring Jekyll itself

module Jekyll
	class Site
		attr_accessor :config, :dest, :static_files
		def initialize(config)
			self.config = config.clone
			self.dest = nil
			self.static_files = []
		end
	end
	class Plugin
		def self.safe(safe = nil)
		end
		def self.priority(priority = nil)
		end
	end
	class Generator < Plugin
	end
	class StaticFile
		def initialize(site, base, dir, name)
		end
		def write(dest)
		end
	end
end