# The CSS Build Tool. Responsible for compiling stylesheets.
# This tool depends on specific hooks to be defined in order
# to perform compilation.

require 'fileutils'
require 'tmpdir'
require 'digest/md5'

module Jekyll
	############
	# The Tool #
	############

	class CssBuildGenerator < Tools::Tool
		name :cssbuild

		def generate(site, settings)
			defaults = settings['defaults']
			settings.delete('defaults')
			default_hooks = Tools::Hooks.new(defaults['hooks'])

			settings.each_pair do |build_target, target_settings|
				build_target_hooks = Tools::Hooks.new(target_settings['hooks'], default_hooks)
				target_settings = defaults.merge(target_settings) if defaults.kind_of? Hash
				site.static_files << CompiledCssFile.new(site, build_target, target_settings, build_target_hooks)
			end
		end
	end

	class CompiledCssFile < StaticFile
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
				main = @settings['main']

				excludes << main
				files = Tools::FileHelpers.get_namespaced_files(includes, excludes)
				files << main

				return files
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
			output = ''
			main = @settings['main']
			tmpdir = File.join(Dir.tmpdir, 'cssbuild')
			Dir.mkdir tmpdir if !File.directory?(tmpdir)
			include_paths = [tmpdir];
			files = source_files

			files.each do |file| self.mtimes[file] = File.stat(file).mtime.to_i end

			namespaced_files = [];
			files.each { |f| namespaced_files << f if f.respond_to?(:namespace) }
			files.delete_if { |f| f.respond_to?(:namespace) }

			FileUtils.cp_r(files, tmpdir)

			namespaced_files.each do |f|
				dest = File.join(tmpdir, f.namespace)
				FileUtils.mkdir_p(dest) unless File.directory?(dest)
				include_paths << dest unless include_paths.include?(dest)
				FileUtils.cp_r(f.to_s, dest)
			end

			tmp_main_file = File.join(tmpdir, File.basename(main))

			if File.exist? tmp_main_file
				settings = @settings.dup

				output = @hooks.call_hook('pre_compile', tmp_main_file, settings) do |main_file|
					File.read(main_file)
				end

				output = @hooks.call_hook('compile', output, include_paths, settings) do |css|
					css
				end

				output = @hooks.call_hook('post_compile', output, settings) do |css|
					css
				end
			end

			FileUtils.remove_dir(tmpdir, :force => true)

			return output
		end
	end
end