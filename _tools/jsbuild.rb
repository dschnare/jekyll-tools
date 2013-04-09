require 'fileutils'
require 'digest/md5'

module Jekyll
	########################################################
	# Extend the builtin Jekyll classes so that we can add #
	# additional variables to the template data hashes.    #
	########################################################

	class Site
		@@js = {}
		def self.js() @@js end

		alias :site_payload_jsbuild :site_payload
		def site_payload
			payload = site_payload_jsbuild
			payload['site'] = payload['site'].deep_merge({
				'js' => @@js.dup
			})

			# Make all JS paths absolute. This is safe to do
			# because all JS paths are relative to the site root.
			js = payload['site']['js']
			js.each_pair do |k, v|
				js[k] = File.join('/', v)
			end

			payload
		end
	end

	module JSToLiquidRelative
		def self.to_liquid(hash)
			lq = hash.deep_merge({
				'js' => Site.js.dup
			})

			js = lq['js']
			dir = lq['url']
			# If the URL of this page is of the form '/page1/index.html'
			# then we get the dirname of it.
			dir = File.dirname(dir) if !File.extname(dir).empty?
			dirs = dir.split('/')
			# Remove the leading and trailing empty dirs. This occurs
			# from paths like '/' or '/page1/'.
			dirs.shift if dirs.first == ''
			dirs.pop if dirs.last == ''
			# Construct the relative portion of the URL.
			rel = ''
			(1..dirs.length).each { rel << '../' }

			# Prefix the relative portion of the URL to each JS
			# path. We have to do this because all JS paths
			# are relative to the site root.
			js.each_pair do |k, v|
				v = File.join(rel, v)
				# If the URL to the JS file is absolute
				# then we force it to be relative. This will
				# only ever occur for pages that are at the root
				# of your site.
				v = v[1..-1] if v[0] == '/'
				js[k] = v
			end

			lq
		end
	end

	class Page
		alias :to_liquid_jsbuild :to_liquid
		def to_liquid
			JSToLiquidRelative.to_liquid(to_liquid_jsbuild)
		end
	end

	class Post
		alias :to_liquid_jsbuild :to_liquid
		def to_liquid
			JSToLiquidRelative.to_liquid(to_liquid_jsbuild)
		end
	end

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

			Site.js[build_target] = build_target
			# If we want to support @hash in the file name of
			# a build target then we have to compile this file
			# immediately so that the hash is created and saved
			# in the site payload before any page/post is rendered.
			self.write(@site.dest) if @build_target.include?('@hash')
		end

		def mtimes
			if @@instance_mtimes.has_key? @build_target
				return @@instance_mtimes[@build_target]
			end

			return @@instance_mtimes[@build_target] = {}
		end

		def write(dest)
			if @build_target.include?('@hash')
				# Have to always compile build targets with a hash
				# because we don't know the file name they will saved
				# as. Also, these build targets have to be built immediately
				# and as such are built a second time during the normal
				# Jekyll static file write process. We build these files
				# twice because some times their parent directories are
				# marked for deletion and so we must compile them again,
				# albeit they will still have the same file name.
				# WARNING: There is still the issue of a build target that
				# contains @hash AND depends on another build target. The
				# pages will not reflect the proper file name of the build target.
				# return false unless requires_compile?

				compiled_output = compile()
				update_filename_hash(compiled_output)
				dest_path = destination(dest)
				FileUtils.mkdir_p(File.dirname(dest_path))
				File.open(dest_path, 'w') do |f|
					f.write compiled_output
				end

				return true
			else
				dest_path = destination(dest)
				return false if File.exists?(dest_path) and !requires_compile?

				compiled_output = compile()
				FileUtils.mkdir_p(File.dirname(dest_path))
				File.open(dest_path, 'w') do |f|
					f.write compiled_output
				end

				return true
			end
		end

		def update_filename_hash(compiled_output)
			if @build_target.include?('@hash')
				digest = Digest::MD5.hexdigest(compiled_output)
				hashed_build_target = @build_target.gsub('@hash', digest)
				Site.js[@build_target] = hashed_build_target
				@name = File.basename(hashed_build_target)
			end
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