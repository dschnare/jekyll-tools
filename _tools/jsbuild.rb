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
			default_hooks = Hooks.new(defaults['hooks'])

			settings.each_pair do |build_target, target_settings|
				# The settings for each target could be an array of file patterns to include.
				if target_settings.kind_of?(Array)
					target_settings = {'include' => target_settings}
				else
					target_settings = defaults.merge(target_settings)
				end

				target_hooks = Hooks.new(target_settings['hooks'], default_hooks)
				site.static_files << CompiledJavaScriptFile.new(site, build_target, target_settings, target_hooks)
			end
		end
	end

	class CompiledJavaScriptFile < StaticFile
		def initialize(site, file, settings, hooks)
			super(site, site.source, File.dirname(file), File.basename(file))
			@file = file
			@settings = settings
			@hooks = hooks
			@mtimes = {}

			# We have to compile right away so we can set a site variable
			# that contains the file name of the JavaScript file with the hash.
			# We do this here because static files are written last.
			@compiled_output = compile()

			Site.js[@file] = @file

			if !@compiled_output.empty? and @file.include?('@hash')
				@digest = Digest::MD5.hexdigest(@compiled_output)
				hashed_filename = @file.gsub('@hash', @digest)
				@name = File.basename(hashed_filename)
				Site.js[@file] = hashed_filename
			end
		end

		def write(dest)
			dest_path = destination(dest)
			written = false
			write = Proc.new do
				FileUtils.mkdir_p(File.dirname(dest_path))
				File.open(dest_path, 'w') do |f|
					f.write @compiled_output
					written = true
				end
			end

			if !@compiled_output.empty?
				if (@digest)
					old_digest = Digest::MD5.hexdigest(File.read(dest_path)) if File.exist?(dest_path)
					if (old_digest != @digest)
						write.call
					end
				else
					write.call
				end
			end

			written
		end

		def compile()
			output = ''

			if @settings.has_key? 'include'
				includes = @settings.get_as_array('include')
				excludes = @settings.get_as_array('exclude')
				files = FileHelpers.get_files(includes, excludes)
				source_modified = false

				files.each do |file|
					last_modified = File.stat(file).mtime.to_i

					if @mtimes[file] != last_modified
						@mtimes[file] = last_modified
						source_modified = true
					end
				end

				if source_modified
					settings = @settings.dup

					output = FileHelpers::combine(files) do |filename, content|
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
				end
			end

			return output
		end
	end
end