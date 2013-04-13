# The copy Tool. Responsible for copying files to a copy target (i.e. a folder).

require 'fileutils'

module Jekyll
	class CopyGenerator < Tools::Tool
		name :copy

		def generate(site, settings)
			defaults = settings['defaults']
			settings.delete('defaults')
			default_hooks = Tools::Hooks.new(defaults['hooks'])

			settings.each_pair do |copy_target, target_settings|
				# The settings for each target could be an array of file patterns to include.
				if target_settings.kind_of?(Array)
					target_settings = {'include' => target_settings}
				else
					target_settings = defaults.merge(target_settings)
				end

				copy_target_hooks = Tools::Hooks.new(target_settings['hooks'], default_hooks)
				files = get_files_to_copy(target_settings)

				if target_settings.has_key? 'include'
					copy_target = File.dirname(copy_target) if File.file?(copy_target)
					create_jekyll_files(site, copy_target, files, copy_target_hooks, target_settings)
				end
			end
		end

		def get_files_to_copy(settings)
			preserve_dirs = settings.get('preserve_dirs', @preserve_dirs)
			includes = settings.get_as_array('include')
			excludes = settings.get_as_array('exclude')
			files = []

			includes.each do |pattern|
				# Example: some/dir/**/other/dir/file.txt
				# base = some/dir
				# dir = subdir1/subdir2/other/dir
				# name = file.txt
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
				# Example: some/dir/other/dir/file.txt
				# base = some/dir/other/dir
				# dir = ''
				# name = file.txt
				else
					sources = Dir.glob pattern
					sources.each do |source|
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
					files.delete_if do |f|
						File.join(f[:base], f[:dir], f[:name]) == excl
					end
				end
			end

			files
		end

		def create_jekyll_files(site, copy_target, files, hooks, settings)
			files.each do |file|
					site.static_files << CopiedStaticFile.new(site, file[:base], file[:dir], file[:name], copy_target, hooks, settings)
			end
		end
	end

	class CopiedStaticFile < StaticFile
		def initialize(site, base, dir, name, dest_dir, hooks, settings)
			super(site, base, dir, name)
			@dest_dir = dest_dir
			@hooks = hooks
			@settings = settings
		end

		def destination(dest)
			File.join(dest, @dest_dir, @dir, @name)
		end

		def write(dest)
			written = false

			get_destination_dirs(dest).each do |d|
				dest_path = File.join(d, @name)

				if !File.exist?(dest_path) or modified?
					written = true
					@@mtimes[path] = mtime
					FileUtils.mkdir_p(d)

					@hooks.call_hook('copy_file', path, dest_path, @settings.dup) do |source_path, dest_path|
						FileUtils.cp_r(source_path, dest_path)
					end
				end
			end

			written
		end

		# If destination is a glob pattern then will get a list
		# of all directories we are to copy files to. Some directories
		# may or may not exist so they will have to be created.
		#
		# Example: page[0-9]/docs
		#  Will get all the directories that match page[0-9]/docs.
		#  The sub directory docs/ does not have to exist.
		def get_destination_dirs(destination)
			if @dest_dir =~ /\*|\?|\}|\]/
				glob = File.join(destination, @dest_dir, @dir)
				dirs = glob.split('/')
				leaf = ''
				list = []

				while (true)
					break if glob == '.'
					list = Dir.glob(glob)
					break unless list.empty?
					# No files found so we save them to the leaf
					# then remove the last directory from glob
					leaf = File.join(dirs.pop, leaf)
					glob = File.dirname(glob)
				end

				# Concatenate the leaf to each file in the list
				list.map { |d| File.join(d, leaf) }
			else
				[File.join(destination, @dest_dir, @dir)]
			end
		end
	end
end