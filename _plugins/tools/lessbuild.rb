require 'fileutils'
require 'tmpdir'
require 'digest/md5'
require_relative 'lib/helpers.rb'
require_relative 'lib/hooks.rb'

module Jekyll
	########################################################
	# Extend the builtin Jekyll classes so that we can add #
	# additional variables to the template data hashes.    #
	########################################################

	class Site
		@@css = {}
		def self.css() @@css end

		alias :css_site_payload :site_payload

		def site_payload
			payload = css_site_payload
			payload['site'] = payload['site'].deep_merge({
				'css' => @@css.dup
			})

			# Make all CSS paths absolute. This is safe to do
			# because all CSS paths are relative to the site root.
			css = payload['site']['css']
			css.each_pair do |k, v|
				css[k] = File.join('/', v)
			end

			payload
		end
	end

	module CSSToLiquidRelative
		def self.to_liquid(hash)
			lq = hash.deep_merge({
				'css' => Site.css.dup
			})

			css = lq['css']
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

			# Prefix the relative portion of the URL to each CSS
			# path. We have to do this because all CSS paths
			# are relative to the site root.
			css.each_pair do |k, v|
				v = File.join(rel, v)
				# If the URL to the CSS file is absolute
				# then we force it to be relative. This will
				# only ever occur for pages that are at the root
				# of your site.
				v = v[1..-1] if v[0] == '/'
				css[k] = v
			end

			lq
		end
	end

	class Page
		alias :css_to_liquid_orig :to_liquid
		def to_liquid
			CSSToLiquidRelative.to_liquid(css_to_liquid_orig)
		end
	end

	class Post
		alias :css_to_liquid_orig :to_liquid
		def to_liquid
			CSSToLiquidRelative.to_liquid(css_to_liquid_orig)
		end
	end

	##############
	# The Plugin #
	##############

	class LessBuildGenerator < Generator
		def generate(site)
			config = site.config

			if config.has_key? 'lessbuild' and config['lessbuild'].kind_of?(Hash)
				default_hooks = Hooks.new(config['lessbuild']['hooks'])
				config['lessbuild'].delete 'hooks'

				config['lessbuild'].each_pair do |build_target, settings|
					build_target_hooks = Hooks.new(settings['hooks'], default_hooks)
					settings.delete 'hooks'
					site.static_files << CompiledLessFile.new(site, build_target, settings, build_target_hooks)
				end
			end
		end
	end

	class CompiledLessFile < StaticFile
		def initialize(site, file, settings, hooks)
			super(site, site.source, File.dirname(file), File.basename(file))
			@file = file
			@settings = settings
			@hooks = hooks

			# We have to compile right away so we can set a site variable
			# that contains the file name of the JavaScript file with the hash.
			# We do this here because static files are written last.
			@compiled_output = compile()

			Site.css[@file] = @file

			if !@compiled_output.empty? and @file.include?('@hash')
				@digest = Digest::MD5.hexdigest(@compiled_output)
				hashed_filename = @file.gsub('@hash', @digest)
				@name = File.basename(hashed_filename)

				Site.css[@file] = hashed_filename
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

			if @settings.has_key? 'main'
				includes = @settings.get_as_array('include')
				excludes = @settings.get_as_array('exclude')
				main = @settings['main']
				source_modified = false

				excludes << main
				files = FileHelpers.get_namespaced_files(includes, excludes)
				files << main

				files.each do |file|
					last_modified = File.stat(file).mtime.to_i

					if @@mtimes[file] != last_modified or File.exist?(file)
						@@mtimes[file] = last_modified
						source_modified = true
					end
				end

				if source_modified
					tmpdir = File.join(Dir.tmpdir, 'lessbuild')
					Dir.mkdir tmpdir if !File.directory?(tmpdir)
					include_paths = [tmpdir];

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
						@hooks.call_hook('pre_compile', tmp_main_file)

						output = @hooks.call_hook('compile', tmp_main_file, include_paths.join(':')) do |main_file, include_paths|
							File.read(main_file)
						end

						output = @hooks.call_hook('post_compile', output) do |css|
							css
						end
					end

					FileUtils.remove_dir(tmpdir, :force => true)
				end
			end

			return output
		end
	end
end