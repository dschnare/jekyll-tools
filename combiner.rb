# Jekyll Combiner
# 1.1.3

# Author: Mathieu Bouchard
#         matb33@gmail.com
#         @matb33
#         http://www.matb33.me/

require "digest/md5"
require "logger"

module Jekyll

	class CombinerGenerator < Generator
		safe true
		priority :low

		@site = nil
		@log = nil

		def generate(site)
			@site = site

			is_silent = @site.config["combiner"].has_key?("silent") ? @site.config["combiner"]["silent"] : false

			@log = Logger.new(STDOUT)
			@log.level = is_silent ? Logger::FATAL : Logger::DEBUG

			process
		end

		def process
			less = LESSProcessor.new(@site, @log)
			less.process

			js = JSProcessor.new(@site, @log)
			js.process

			copy = CopyProcessor.new(@site, @log)
			copy.process

			@log.info "Combiner process completed."

			# We don't call cleanup because if someone uses an existing folder
			# as their temp folder (such as /tmp), we don't want to remove that.
			#clean_up
		end

		def clean_up
			if @site.config["combiner"].has_key? "tmp"
				tmp_dir = @site.config["combiner"]["tmp"]
				if (File.directory?(tmp_dir))
					FileUtils.rmtree(tmp_dir)
				end
			end
		end
	end

	class CombinerProcessor
		@site = nil
		@log = nil
		@settings = nil

		def initialize(site, log)
			@site = site
			@log = log
			@settings = site.config["combiner"]
		end

		def get_files(pattern)
			files = []

			Dir.glob(pattern).each do |file|
				files << file
			end

			return files
		end

		def exclude_files(files, pattern)
			files.delete_if do |filename|
				filename.index(pattern)
			end
			return files
		end

		def copy_files(files, output_dir)
			output_files = []

			files.each do |input_file|
				output_file = File.join(output_dir, File.basename(input_file))

				if write(output_file, File.read(input_file))
					output_files << output_file
				end
			end

			return output_files
		end

		def token_replace(str, map)
			str.gsub(/:(\w+)/) do |match|
				key = $1.to_sym
				if map.has_key?(key)
					map[key]
				end
			end
		end

		def write(output_file, content, hash_out = nil)
			do_write = false

			new_md5 = Digest::MD5.hexdigest(content)
			final_output_file = token_replace(output_file, :hash => new_md5)

			# It's important not to write a file if the contents haven't changed
			# otherwise jekyll --auto will pick it up in an infinite loop
			if File.exist?(final_output_file)
				# @log.info "File exists, calculate md5"
				existing_md5 = Digest::MD5.hexdigest(File.read(final_output_file))

				# @log.info "md5 checksums: " + existing_md5 + " vs " + new_md5
				if (existing_md5 != new_md5)
					do_write = true
				end
			else
				do_write = true
			end

			if do_write
				msg = "Writing " + final_output_file + "... "
				begin
					FileUtils.mkdir_p(File.dirname(final_output_file))
					File.open(final_output_file, "w") do |out|
						out.write content
					end
					msg << "OK"
					@log.info msg

					if hash_out != nil
						write_hash(hash_out, new_md5, output_file)
					end
				rescue
					msg << "Error"
					@log.error msg
				end
			end

			return do_write
		end

		def write_hash(hash_out, hash_value, output_file)
			if File.exist?(hash_out)
				old_hash_value = File.read(hash_out)
				if old_hash_value != hash_value
					# The hash value has changed, we should remove the old output file
					old_output_file = token_replace(output_file, :hash => old_hash_value)
					if File.exist?(old_output_file)
						@log.info "Deleting unused " + old_output_file
						File.unlink(old_output_file)
					end
				end
			else
				FileUtils.mkdir_p(File.dirname(hash_out))
			end

			File.open(hash_out, "w") do |out|
				@log.info "Writing " + hash_value + " to " + hash_out
				out.write hash_value
			end
		end

		def get_tmp_dir(type)
			tmp_dir = File.join(@settings["tmp"], type)

			if (!File.directory?(tmp_dir))
				FileUtils.mkdir_p(tmp_dir)
			end

			return File.expand_path(tmp_dir)
		end

		def del_tmp_dir(tmp_dir)
			if (File.directory?(tmp_dir))
				FileUtils.rmtree(tmp_dir)
			end
		end

		def push_static_file(file)
			base = @site.dest
			dir = "/" + File.dirname(file) + "/"
			name = File.basename(file)

			@site.static_files << Jekyll::StaticAssetFile.new(@site, base, dir, name)
		end
	end

	####################
	# JS
	####################

	#combiner:
	#  js:
	#    combine:
	#    - in: ['pattern1', 'pattern2', 'pattern3']
	#      not: ['pattern1', 'pattern2']
	#      out: 'gen/output_file.min.js'
	#      hash: 'hash_value_in_file.txt'
	#      uglify: true/false
	#    - in: ['pattern1', 'pattern2', 'pattern3']
	#      not: ['pattern1', 'pattern2']
	#      out: 'gen/output_file2.min.js'
	#      hash: 'hash_value_in_file.txt'
	#      uglify: true/false

	class JSProcessor < CombinerProcessor
		def process()
			if @settings.has_key? "js"
				@log.info "Processing JS..."

				settings = @settings["js"]

				if settings.has_key? "combine"
					settings["combine"].each do |set|
						if set.has_key? "in" and set.has_key? "out"
							output_file = set["out"]
							patterns = set["in"].kind_of?(Array) ? set["in"] : [set["in"]]
							hash_out = set.has_key?("hash") ? set["hash"] : nil
							files = []

							@log.info "Gathering JS files"
							patterns.each do |pattern|
								files = files + get_files(pattern)
							end

							if set.has_key? "not"
								@log.info "Applying exclusion patterns"
								patterns = set["not"].kind_of?(Array) ? set["not"] : [set["not"]]
								patterns.each do |pattern|
									files = exclude_files(files, pattern)
								end
							end

							@log.info "Combining JS"
							content = combine(files)

							if set.has_key? "uglify" and set["uglify"] == true
								@log.info "Uglyfing JS"
								content = uglify(content)
							end

							if write(output_file, content, hash_out)
								push_static_file(output_file)
							end
						else
							@log.error "in and out not specified"
						end
					end
				else
					@log.error "combine section not defined"
				end
			end
		end

		def combine(files)
			content = ""

			files.each do |file|
				content = content << File.read(file)
			end

			return content
		end

		def uglify(raw_js)
			require "uglifier"

			minifier = Uglifier.new
			min_js = minifier.compile(raw_js)

			return min_js
		end
	end

	####################
	# LESS
	####################

	#combiner:
	#  less:
	#    command: 'node lib/lessjs/bin/lessc --compress --include-path=:tmp -'
	#    compile:
	#    - in: ['pattern1', 'pattern2', 'pattern3']
	#      not: ['pattern1', 'pattern2']
	#      out: 'gen/output_file.min.css'
	#      hash: 'hash_value_in_file.txt'
	#      root: 'input_file.less'
	#    - in: ['pattern1', 'pattern2', 'pattern3']
	#      not: ['pattern1', 'pattern2']
	#      out: 'gen/output_file2.min.css'
	#      hash: 'hash_value_in_file.txt'
	#      root: 'input_file2.less'

	class LESSProcessor < CombinerProcessor
		def process()
			if @settings.has_key? "less"
				@log.info "Processing LESS..."

				settings = @settings["less"]

				if settings.has_key? "command"
					command = settings["command"]

					if settings.has_key? "compile"
						settings["compile"].each do |set|
							if set.has_key? "in" and set.has_key? "out" and set.has_key? "root"
								output_file = set["out"]
								patterns = set["in"].kind_of?(Array) ? set["in"] : [set["in"]]
								hash_out = set.has_key?("hash") ? set["hash"] : nil
								root_file = set["root"]
								files = []

								@log.info "Gathering LESS files"
								patterns.each do |pattern|
									files = files + get_files(pattern)
								end

								if set.has_key? "not"
									@log.info "Applying exclusion patterns"
									patterns = set["not"].kind_of?(Array) ? set["not"] : [set["not"]]
									patterns.each do |pattern|
										files = exclude_files(files, pattern)
									end
								end

								@log.info "Copying LESS files"
								tmp_dir = get_tmp_dir("combiner_less_files")
								copy_files(files, tmp_dir)

								tmp_root_file = File.join(tmp_dir, root_file)

								if File.exist?(tmp_root_file)
									@log.info "Compiling LESS files"

									# We are compiling using command because this allows more flexibility for
									# the user in defining command-line parameters. Also, the less-js-source
									# gem is grossly out of date.
									css = compile_using_command(command, tmp_root_file, tmp_dir)

									@log.info "Attempting to write final output CSS file"
									if write(output_file, css, hash_out)
										push_static_file(output_file)
									end

									del_tmp_dir(tmp_dir)
								else
									@log.error "root_file [" + root_file + "] not found"
								end
							else
								@log.error "in, out and root not specified"
							end
						end
					else
						@log.error "compile section not defined"
					end
				else
					@log.error "command section not defined"
				end
			end
		end

		def compile_using_command(command, root_file, tmp_dir)
			require "open3"

			content = File.read(root_file)
			result = content
			command = token_replace(command, :tmp => tmp_dir)

			begin
				Open3.popen3(command) do |stdin, stdout, stderr|
					stdin.puts(content)
					stdin.close
					result = stdout.read
					error = stderr.read
					stdout.close
					stderr.close

					if error.length > 0
						@log.error error
					end
				end
			end

			return result
		end

		def compile_using_gem(root_file, tmp_dir)
			result = ""

			begin
				result = less_js_compile(File.read(root_file), tmp_dir)
			rescue StandardError => e
				@log.error e.message
			end

			return result
		end

		def less_js_compile(source, tmp_dir)
			require "execjs"
			require "less_js/source"

			less_js_source ||= File.read(ENV['LESSJS_SOURCE_PATH'] || LessJs::Source.bundled_path)

			context ||= ExecJS.compile <<-EOS
				#{less_js_source}

				function compile(data) {
					var result;
					new(less.Parser)({
						paths: ['#{tmp_dir}']
					}).parse(data, function(error, tree) {
						result = [error, tree.toCSS()];
					});
					return result;
				}
			EOS

			error, data = context.call("compile", source)

			if error
				raise error["message"]
			end

			return data
		end
	end

	####################
	# COPY
	####################

	#combiner:
	#  copy:
	#  - in: ['pattern1', 'pattern2', 'pattern3']
	#    not: ['pattern1', 'pattern2']
	#    out: 'output/folder'
	#  - in: ['pattern1', 'pattern2', 'pattern3']
	#    not: ['pattern1', 'pattern2']
	#    out: 'output/folder2'

	class CopyProcessor < CombinerProcessor
		def process()
			if @settings.has_key? "copy"
				@log.info "Processing copy operations..."

				@settings["copy"].each do |set|
					if set.has_key? "in" and set.has_key? "out"
						output_folder = set["out"]
						patterns = set["in"].kind_of?(Array) ? set["in"] : [set["in"]]
						files = []

						@log.info "Gathering arbitrary files"
						patterns.each do |pattern|
							files = files + get_files(pattern)
						end

						if set.has_key? "not"
							@log.info "Applying exclusion patterns"
							patterns = set["not"].kind_of?(Array) ? set["not"] : [set["not"]]
							patterns.each do |pattern|
								files = exclude_files(files, pattern)
							end
						end

						@log.info "Copying arbitrary files"
						copy_files(files, output_folder)
					else
						@log.error "in and out not specified"
					end
				end
			end
		end
	end

	# Sub-class Jekyll::StaticFile to allow recovery from unimportant exception
	# when writing the file.
	class StaticAssetFile < StaticFile
		def write(dest)
			super(dest) rescue ArgumentError
			true
		end
	end
end