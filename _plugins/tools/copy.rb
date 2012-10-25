require 'fileutils'
require_relative 'lib/helpers.rb'
require_relative 'lib/hooks.rb'

module Jekyll
	class CopyGenerator < Generator
		priority :lowest

		def generate(site)
			config = site.config

			if config.has_key? 'copy' and config['copy'].kind_of?(Hash)
				default_hooks = Hooks.new(config['copy']['hooks'])
				@preserve_dirs = config['copy'].get('preserve_dirs', false)

				config['copy'].delete 'hooks'
				config['copy'].delete 'preserve_dirs'

				# Iterate over each target.
				# Each key is the destination directory where to copy the files to.
				config['copy'].each_pair do |copy_target, settings|
					# The settings for each target could be an array of file patterns to include.
					if settings.kind_of?(Array)
						settings = {'include' => settings}
					end

					copy_target_hooks = Hooks.new(settings['hooks'], default_hooks)
					files = getFilesToCopy(settings)

					if settings.has_key? 'include'
						copy_target = File.dirname(copy_target) if File.file?(copy_target)
						createJekyllFiles(site, copy_target, files, copy_target_hooks)
					end
				end
			end
		end

		def createJekyllFiles(site, copy_target, files, hooks)
			files.each do |file|
				# If the file is refering to file(s) that dont exist yet
				# then we create a CompositeCopiedStaticFile that will
				# generate new static files when it is about to be written.
				# These new static files are appended to site#static_files
				# as the array is being traversed. This works perfectly
				# fine since the array#each enumerator will enumerate newly added items.
				if file.has_key? :getFiles
					site.static_files << CompositeCopiedStaticFile.new(site, file, copy_target, hooks)
				# Otherwise the file we are about to copy actual exists so we just create
				# a CopiedStaticFile and append it to site#static_files.
				else
					site.static_files << CopiedStaticFile.new(site, file[:base], file[:dir], file[:name], copy_target, hooks)
				end
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
					sources = Dir.glob pattern
					# This include pattern does not exist yet.
					# This pattern may be pointing at a file that
					# has yet to be generated so we create a proc that will
					# run this pattern at a later time.
					if sources.empty?
						files << {
							:getFiles => Proc.new do
								_files = []

								Dir.glob pattern do |source|
									_files << {
										:base => File.dirname(source),
										:dir => '',
										:name => File.basename(source)
									}
								end

								excludes.each do |pattern|
									Dir.glob pattern do |excl|
										_files.delete_if { |f| File.join(f[:base], f[:dir], f[:name]) == excl }
									end
								end

								_files
							end
						}
					else
						sources.each do |source|
							files << {
								:base => File.dirname(source),
								:dir => '',
								:name => File.basename(source)
							}
						end
					end
				end
			end

			excludes.each do |pattern|
				Dir.glob pattern do |excl|
					files.delete_if do |f|
						File.join(f[:base], f[:dir], f[:name]) == excl unless f.has_key? :getFiles
					end
				end
			end

			files
		end
	end

	class CompositeCopiedStaticFile < StaticFile
		def initialize(site, filedata, dest_dir, hooks)
			super(site, '', '', '')
			@filedata = filedata
			@dest_dir = dest_dir
			@hooks = hooks
		end

		def write(dest)
			files = @filedata[:getFiles].call()

			files.each do |file|
				@site.static_files << CopiedStaticFile.new(@site, file[:base], file[:dir], file[:name], @dest_dir, @hooks)
			end

			false
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

			if @name == 'main.js'
				puts "#{getDirs} -- #{path} -- #{File.exists?(path)}"
			end

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