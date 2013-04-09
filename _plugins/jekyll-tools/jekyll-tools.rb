require_relative 'helpers.rb'
require_relative 'hooks.rb'

module Jekyll
	# Extend the Jekyll Site class so that we load and 
	# instantiate all Jekyll tools just like any other Jekyll plugin.
	class Site
		attr_accessor :tools

		def setup_tools
			if @tool_files.nil?
				@tool_files = self.tools_path
				self.tools = {}

				@tool_files.each do |dir|
					Dir[File.join(dir, "**/*.rb")].each do |f|
						require f
					end
				end

				instantiate_subclasses(Jekyll::Tools::Tool).each do |tool|
					self.tools[tool.class.name] = tool;
				end
			end
		end

		def tools_path
			config = self.config.get_as_hash('tools')
			if (config['path'] == Jekyll::Tools::DEFAULTS['path'])
				[File.join(self.source, config['path'])]
			else
				Array(config['path']).map { |d| File.expand_path(d) }
			end
		end
	end

	# The Jekyll generator that will run all Jekyll tools.
	class JekyllTools < Generator
		priority :lowest

		def generate(site)
			site.setup_tools

			site_config = site.config
			tools = site_config.get('tools', {})

			if tools.kind_of?(Hash)
				defaults = tools.get_as_hash('defaults')

				tools.get_as_array('tasks').each do |hash|
					hash.each_pair do |tool_name, settings|
						if settings.kind_of?(Hash) and
								site.tools.has_key?(tool_name)
							settings['defaults'] = defaults.get_as_hash(tool_name)
							site.tools[tool_name].generate(site, settings)
						end
					end
				end
			end
		end
	end

	# The Tools namespace that contains the base class for all Jekyll tools.
	module Tools
		DEFAULTS = {
			'path' => '_tools'
		}

		class Tool < Jekyll::Plugin
			def self.name(name = nil)
				@name = name.to_s if name
				@name || 'n/a'
			end

			def generate(site, settings)
				# Do stuff
			end
		end
	end
end