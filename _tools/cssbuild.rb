require 'fileutils'
require 'tmpdir'
require 'digest/md5'

module Jekyll
	########################################################
	# Extend the builtin Jekyll classes so that we can add #
	# additional variables to the template data hashes.    #
	########################################################

	class Site
		@@css = {}
		def self.css() @@css end

		alias :site_payload_cssbuild :site_payload
		def site_payload
			payload = site_payload_cssbuild
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
		alias :to_liquid_cssbuild :to_liquid
		def to_liquid
			CSSToLiquidRelative.to_liquid(to_liquid_cssbuild)
		end
	end

	class Post
		alias :to_liquid_cssbuild :to_liquid
		def to_liquid
			CSSToLiquidRelative.to_liquid(to_liquid_cssbuild)
		end
	end

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

			Site.css[build_target] = build_target
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
				return false unless requires_compile?

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
				Site.css[@build_target] = hashed_build_target
				@name = File.basename(hashed_build_target)
			end
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