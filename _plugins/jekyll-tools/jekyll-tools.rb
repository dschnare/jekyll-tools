# The entry point for the Jekyll Tools plugin.

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

	# Tag that produces a random string consisting 
	# of upper and lowercase alphabetic characters
	# and digits.
	#
	# Example: {% random_string 5 %}
	# Where 5 is the length of the string.
	# Default length is 20 characters.
	#
	# Reference: http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
	class RandomStringTag < Liquid::Tag
		def initialize(tag_name, length, tokens)
			super
			@length = length.to_i
			@length = 20 if @length <= 0
		end

		def render(context)
			o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
			return (0...@length).map{ o[rand(o.length)] }.join
		end
	end

	Liquid::Template.register_tag('random_string', Jekyll::RandomStringTag)
end