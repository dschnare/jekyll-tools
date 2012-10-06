=begin

This plugin compiles LESS stylesheets starting at a source/main stylesheet that
includes all dependent stylesheets. Compilation is determined by hooks specified
in the config.yml file. If there is no 'compile' hook then no compilation occurs.

This plugin comes with example hooks at ./hooks/lessbuild.hook. The extension
of this file is '.hook' so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping 'lessbuild' must be present in config.yml for this plugin to run.

NOTE: All paths are relative to the project root unless otherwise stated.


Config
----------------

NOTE: There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

lessbuild:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.
  # Your hook file must contain a 'compile' hook for
  # compilation to occur.

  hooks: _plugins/build/hooks/lessbuild.hook

  # Every other key represents a build target, where
  # the key is a CSS file relative to the 'destination' setting.
  #
  # To include this file in your HTML you simply use the build target
  # filename:
  #   <link rel="stylesheet" type="text/css" href="inc/css/main.min.css" />

  inc/css/main.min.css:
    # An optional path to a custom hook file for this build target.
    # This will override any default hooks.

  	hooks: _hooks/lessbuild-custom.rb

  	# The path to the main LESS stylesheet.

    main: _src/less/main.less

    # Sequence of files to include in the build.

    include:
      - _src/less/**/*.less
      - _assets/vendor/bootstrap/less/*.less

    # An optional sequence of files to exclude form the build.

    exclude:
      - _src/less/themes/**/*.less


  # This form inserts a MD5 hash of the compiled CSS file into
  # the build target name. The token @hash will be replaced with the MD5 digest.
  #
  # To include this file in your HTML you must use the variable on the site
  # template data hash. The variable name is your build target name:
  #   <link rel="stylesheet" type="text/css" href="{{ site["inc/css/main-@hash.css"] }}" />

  inc/css/main-@hash.css:
  	hooks: _hooks/lessbuild-custom.rb
    main: _src/less/main.less
    include:
      - _src/less/**/*.less
      - _assets/vendor/bootstrap/less/*.less

Hooks
----------------

See ./hooks/lessbuild.rb for documentation and examples.

=end

require 'fileutils'
require 'tmpdir'
require 'digest/md5'
require_relative 'lib/helpers.rb'
require_relative 'lib/hooks.rb'

module Jekyll
	class LessBuildGenerator < Generator
		def generate(site)
			@hooks = Hooks.new if @hooks.nil?
			config = site.config

			if config.has_key? 'lessbuild'
				@hooks << config['lessbuild']['hooks']
				config['lessbuild'].delete 'hooks'

				config['lessbuild'].each_pair do |build_target, settings|
					@hooks << settings['hooks']
					settings.delete 'hooks'
					site.static_files << CompiledLessFile.new(site, build_target, settings, @hooks)
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

			if !@compiled_output.empty? and @file.include?('@hash')
				@digest = Digest::MD5.hexdigest(@compiled_output)
				hashed_filename = @file.gsub('@hash', @digest)
				@name = File.basename(hashed_filename)
				@site.config[@file] = hashed_filename
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

			if @settings.has_key? 'include' and @settings.has_key? 'main'
				includes = @settings.get_as_array('include')
				excludes = @settings.get_as_array('exclude')
				main = @settings['main']
				source_modified = false

				excludes << main
				files = FileHelpers.get_files(includes, excludes)
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
					FileUtils.cp(files, tmpdir)

					tmp_main_file = File.join(tmpdir, File.basename(main))

					if File.exist? tmp_main_file
						@hooks.call_hook('pre_compile', tmp_main_file)

						output = @hooks.call_hook('compile', tmp_main_file) do |main_file|
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