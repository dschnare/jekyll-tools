=begin

This plugin will combine JavaScript files and optionally compile the combined file.
Compilation is determined by hooks specified in the _config.yml file. If there is
no 'compile' hook then no compilation occurs.

This plugin comes with example hooks at ./hooks/jsbuild.hook. The extension
of this file is '.hook' so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping 'jsbuild' must be present in _config.yml for this plugin to run.

NOTE: All paths are relative to the project root unless otherwise stated.


Config
---------------------

NOTE: There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

jsbuild:
  # An optional path to a custom hook file. This will be the
  # default hooks unless overriden by a build target.

  hooks: _plugins/build/hooks/jsbuild.hook

  # Every other key represents a build target, where the key
  # is a JavaScript file relative to the 'destination' setting.
  # This form is a simple build target where only included files
  # are listed in a sequence.
  #
  # To include this file in your HTML you simply use the build target
  # filename:
  #  <script type="text/javascript" src="inc/js/main.min.js"></script>

  inc/js/main.min.js:
    - _src/js/lib/**/*.js
    - _src/js/main.js

  # This form is an advanced build target where custom settings
  # are specified.
  #
  # To include this file in your HTML you simply use the build target
  # filename:
  #  <script type="text/javascript" src="inc/js/main.min.js"></script>

  inc/ns/main.min.js:
  	# Hooks are optional and only apply to this build target. This will override any default hooks.

  	hooks: _hooks/jsbuild-custom.rb

	# Sequence of files to include in the build.

  	include:
      - _src/js/lib/**/*.js
      - _src/js/main.js

	# An optional sequence of files to exclude from the build.

  	exclude
  	  - _src/js/lib/_deprecated/**/*.js


  # This form inserts a MD5 hash of the compiled JavaScript file into
  # the build target name. The token @hash will be replaced with the MD5 digest.
  #
  # To include this file in your HTML you must use the variable on the site
  # template data hash. The variable name is your build target name:
  #  <script type="text/javascript" src="{{ site["inc/js/main-@hash.js"] }}"></script>

  inc/js/main-@hash.js:
    - _src/js/lib/**/*.js
    - _src/js/main.js


Hooks
---------------------

See ./hooks/jsbuild.hook for documentation and examples.


=end

require 'fileutils'
require 'digest/md5'
require_relative 'lib/helpers.rb'
require_relative 'lib/hooks.rb'

module Jekyll
	class JSBuildGenerator < Generator
		priority :higheset

		def generate(site)
			@hooks = Hooks.new if @hooks.nil?
			config = site.config

			if config.has_key? 'jsbuild'
				@hooks << config['jsbuild']['hooks']
				config['jsbuild'].delete 'hooks'

				config['jsbuild'].each_pair do |build_target, settings|
					# The settings for each target could be an array of file patterns to include.
					if settings.kind_of?(Array)
						settings = {'include' => settings}
					end

					@hooks << settings['hooks']
					settings.delete 'hooks'
					site.static_files << CompiledJavaScriptFile.new(site, build_target, settings, @hooks)
				end
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
					output = FileHelpers::combine(files) do |filename, content|
						@hooks.call_hook('pre_combine_file', filename, content) do |file, file_content|
							file_content
						end
					end

					output = @hooks.call_hook('pre_compile', output) do |js|
						js
					end

					output = @hooks.call_hook('compile', output) do |js|
						js
					end

					output = @hooks.call_hook('post_compile', output) do |js|
						js
					end
				end
			end

			return output
		end
	end
end