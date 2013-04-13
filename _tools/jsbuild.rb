# The JS Build Tool. Responsible for combining JS files and minifying the result.

require 'fileutils'
require 'digest/md5'

module Jekyll
	############
	# The Tool #
	############

	class JSBuildGenerator < Tools::Tool
		name :jsbuild

		def generate(site, settings)
			defaults = settings['defaults']
			settings.delete('defaults')
			default_hooks = Tools::Hooks.new(defaults['hooks'])

			settings.each_pair do |build_target, target_settings|
				# The settings for each target could be an array of file patterns to include.
				if target_settings.kind_of?(Array)
					target_settings = {'include' => target_settings}
				else
					target_settings = defaults.merge(target_settings)
				end

				target_hooks = Tools::Hooks.new(target_settings['hooks'], default_hooks)
				site.static_files << CompiledJavaScriptFile.new(site, build_target, target_settings, target_hooks)
			end
		end
	end

	class CompiledJavaScriptFile < StaticFile
		# key = build_target, value = hash of mtimes
		@@instance_mtimes = {}

		def initialize(site, build_target, settings, hooks)
			base = site.dest
			dir = File.dirname(build_target)
			name = File.basename(build_target)
			super(site, base, dir, name)

			@settings = settings
			@hooks = hooks
			@build_target = build_target
		end

		def mtimes
			if @@instance_mtimes.has_key? @build_target
				return @@instance_mtimes[@build_target]
			end

			return @@instance_mtimes[@build_target] = {}
		end

		def write(dest)
			dest_path = destination(dest)
			return false if File.exists?(dest_path) and !requires_compile?

			compiled_output = compile()
			FileUtils.mkdir_p(File.dirname(dest_path))
			File.open(dest_path, 'w') do |f|
				f.write compiled_output
			end

			return true
		end

		def source_files
			if @settings.has_key? 'include'
				includes = @settings.get_as_array('include')
				excludes = @settings.get_as_array('exclude')
				return Tools::FileHelpers.get_files(includes, excludes)
			end

			return []
		end

		def requires_compile?
			source_files.each do |file|
				# Can't compile if a file that's is to be included does not exist.
				return false unless File.exists?(file)
				last_modified = File.stat(file).mtime.to_i
				return true if self.mtimes[file] != last_modified
			end

			return false
		end

		def compile()
			settings = @settings.dup
			source_files = self.source_files
			output = ''

			source_files.each do |file| self.mtimes[file] = File.stat(file).mtime.to_i end

			output = Tools::FileHelpers::combine(source_files) do |filename, content|
				@hooks.call_hook('pre_combine_file', filename, content, settings) do |file, file_content|
					file_content
				end
			end

			output = @hooks.call_hook('pre_compile', output, settings) do |js|
				js
			end

			output = @hooks.call_hook('compile', output, settings) do |js|
				js
			end

			output = @hooks.call_hook('post_compile', output, settings) do |js|
				js
			end

			return output
		end
	end
end