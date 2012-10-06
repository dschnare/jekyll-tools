=begin

The copy plugin will copy files to a directory relative to the 'destination' setting.

This plugin comes with example hooks at ./hooks/copy.hook. The extension
of this file is '.hook' so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping 'copy' must be present in config.yml for this plugin to run.

NOTE: All paths are relative to the project root unless otherwise stated.


Config
--------------

copy:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.

  hooks: _plugins/build/hooks/copy.hook

  # An optional setting to preserve recursive
  # directories in file patterns. Default is false.

  preserve_dirs: true

  # Every other key represents a copy target, where the
  # key is a directory relative to the 'destination' setting.
  # This form is a simple copy target where only files to copy
  # are listed in a sequence.

  inc/img:
  	- _assets/from_design/images/**/*.*
  	- _assets/vendor/bootstrap/images/*.*

  # This form is an advanced copy target where custom settings
  # are specified.

  inc/img:
	# An optional path to a custom hook file for this copy target.
  	# This will override any default hooks.

  	hooks: _hooks/copy-custom.rb

	# An optional setting that preserves recursive directories in
	# file patterns for this copy target only.

  	preserve_dirs: false

    # Sequence of files to copy.

  	include:
  	  - _assets/from_design/images/**/*.*
  	  - _assets/vendor/bootstrap/images/*.*

  	# An optional sequence of files to exclude from copying.

  	exclude:
  	  - _assets/from_design/images/old/**/*.*


  # Copy targets can contain directory glob patterns as well.
  # This will copy the included files to all directories that
  # match the glob. Glob patterns can match directories created
  # by Jekyll in the 'destination' directory.

  webpages/**/docs:
    - _assets/docs/*.pdf

Hooks
--------------

See ./hooks/copy.hook for documentation and examples.



Preserving Recursive Directories
------------------------------------------

By default recursive directories are not preserved when copying, meaning each file
will be copied to the root of its copy target: {destination}/inc/img/{file.ext}

copy:
  inc/img:
    - _vendor/bootstrap/img/**/*.*

Recursive directories can be preserved by setting the 'preserve_dirs' mapping to true.
All images will now have a copy path {destination}/inc/img/{recursive-directories}/{file.ext}

copy:
  inc/img:
    preserve_dirs: true
    include:
      - _vendor/bootstrap/img/**/*.*


The 'preserve_dirs' mapping can be specified at the top-level or on an individual copy target. This mapping
has no effect on patterns that do not match recursive directories (i.e. do not contain '**').

=end

require 'fileutils'
require_relative 'lib/helpers.rb'
require_relative 'lib/hooks.rb'

module Jekyll
	class CopyGenerator < Generator
		priority :lowest
		def generate(site)
			@hooks = Hooks.new if @hooks.nil?
			config = site.config

			if config.has_key? 'copy'
				@settings = config['copy']
				@hooks << @settings['hooks']
				@preserve_dirs = @settings.get('preserve_dirs', false)
				@settings.delete 'hooks'
				@settings.delete 'preserve_dirs'

				# Iterate over each target.
				# Each key is the destination directory where to copy the files to.
				@settings.each_pair do |copy_target, settings|
					# The settings for each target could be an array of file patterns to include.
					if settings.kind_of?(Array)
						settings = {'include' => settings}
					end

					@hooks << settings['hooks']
					files = getFilesToCopy(settings)

					if settings.has_key? 'include'
						copy_target = File.dirname(copy_target) if File.file?(copy_target)
						createJekyllFiles(site, copy_target, files)
					end
				end
			end
		end

		def createJekyllFiles(site, copy_target, files)
			files.each do |file|
				site.static_files << CopiedStaticFile.new(site, file[:base], file[:dir], file[:name], copy_target, @hooks)
			end
		end

		def getFilesToCopy(settings)
			preserve_dirs = settings.get('preserve_dirs', @preserve_dirs)
			includes = settings.get_as_array('include')
			excludes = settings.get_as_array('exclude')
			files = []

			includes.each do |pattern|
				if preserve_dirs and pattern.include? '**'
					base_pattern = pattern.split('**')[0]

					# We have to convert the pattern before the recursive directories to a regular expression.
					# If we don't do this then we can't extract the base from a source file.

					base_pattern.gsub!('.', '\\.') # escape .
					base_pattern.gsub!('\\', '\\\\') # escape \
					base_pattern.gsub!('*', '.*') # replace * with .*
					base_pattern.gsub!('?', '.{1}') # replace ? with .{1}

					# Replace {q,p} with (q|p)
					base_pattern.gsub!(/\{(.+)\}/) do
						"(#{$1.gsub(',', '|')})"
					end

					# Create the regular expression
					base_regex = Regexp.new(base_pattern)

					Dir.glob pattern do |source|
						# Get the base from the source file
						base = base_regex.match(source)[0]
						files << {
							:base => base,
							:dir => File.dirname(source[base.length..-1]),
							:name => File.basename(source)
						}
					end
				else
					Dir.glob pattern do |source|
						files << {
							:base => File.dirname(source),
							:dir => '',
							:name => File.basename(source)
						}
					end
				end
			end

			excludes.each do |pattern|
				Dir.glob pattern do |excl|
					files.delete_if { |f| File.join(f[:base], f[:dir], f[:name]) == excl }
				end
			end

			files
		end
	end

	class CopiedStaticFile < StaticFile
		def initialize(site, base, dir, name, dest_dir, hooks)
			super(site, base, dir, name)
			@dest_dir = dest_dir
			@hooks = hooks
		end

		def destination(dest)
			File.join(dest, @dest_dir, @dir, @name)
		end

		def write(dest)
			written = false

			getDirs.each do |d|
				dest_path = File.join(dest, d, '', @name)

				if !File.exist?(dest_path) or modified?
					written = true
					@@mtimes[path] = mtime

					FileUtils.mkdir_p(File.dirname(dest_path))

					@hooks.call_hook('copy_file', path, dest_path) do |source_path, dest_path|
						FileUtils.cp(source_path, dest_path)
					end
				end
			end

			written
		end

		def getDirs
			if @dest_dir =~ /\*|\?|\}|\]/
				destination = @site.config['destination']
				glob = File.join(destination, @dest_dir, @dir)
				dirs = glob.split('/')
				leaf = ''

				while (true)
					break if glob == '.'
					list = Dir.glob(glob)
					break unless list.empty?
					leaf = "#{dirs.pop}/#{leaf}"
					glob = File.dirname(glob)
				end

				list.map { |d| "#{d}/#{leaf}".gsub(destination, '') }
			else
				[File.join(@site.config['destination'], @dest_dir, @dir)]
			end
		end
	end
end