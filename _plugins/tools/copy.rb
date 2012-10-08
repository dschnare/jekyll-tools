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
						FileUtils.cp_r(source_path, dest_path)
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
				[File.join(@dest_dir, @dir)]
			end
		end
	end
end