require 'fileutils'

# Extend the core Hash class.
class Hash
	# Get the value of a key and return 'default' if no key exists.
	def get(key, default)
		return self[key] if has_key? key
		return default
	end

	# Get the value of the key as an array. If the key value is not an array
	# then a single element array will be returned. If the key does not exist
	# then an empty array is returned.
	def get_as_array(key)
		if has_key? key
			value = self[key]
			return value.kind_of?(Array) ? value : [value]
		end

		return []
	end

	# Get the value of the key as Hash. If the key value is not a Hash or
	# does not exist then an empty hash is returned.
	def get_as_hash(key)
		value = {}

		if has_key? key
			value = self[key] if self[key].kind_of?(Hash)
		end

		return value
	end
end

module Jekyll
	module Tools
		# A string that has a namespace property.
		class NamespacedString < String
			attr_reader :namespace

			def initialize(s, namespace)
				super(s)
				@namespace = namespace
			end
		end

		# File helper functions.
		module FileHelpers
			# Get a list of files that match the specified glob patterns but
			# do not match the exclusion glob patterns.
			#
			# @param incl Array of file patterns to include.
			# @param excl Array of file patterns to exclude.
			# @return Array of file names.
			def self.get_files(incl, excl=nil)
				files = []

				incl.each do |pattern|
					files = files.concat(Dir.glob(pattern))
				end

				# Exclude all directories.
				files.delete_if { |file| File.directory?(file) }

				if excl.kind_of?(Array)
					excl.each do |pattern|
						exclude_files(files, pattern)
					end
				end

				files
			end

			# Get a list of files that match the specified glob patterns but
			# do not match the exclusion glob patterns. The inclusion glob patterns
			# can be represented as a Hash where each key is the namespace each file
			# matched by the pattern will be placed under.
			#
			# @param incl Array of file patterns to include (can be instances of Hash).
			# @param excl Array of file patterns to exclude.
			# @return Array of file names.
			def self.get_namespaced_files(incl, excl)
				files = []

				incl.each do |pattern|
					if pattern.kind_of?(Hash)
						pattern.each_pair do |k, v|
							files = files.concat(Dir.glob(v).map { |f| NamespacedString.new(f, k) })
						end
					else
						files = files.concat(Dir.glob(pattern))
					end
				end

				if excl.kind_of?(Array)
					excl.each do |pattern|
						exclude_files(files, pattern)
					end
				end

				files
			end

			#Exclude files that match the specified glob pattern from the list of files.
			#
			# @param files Array of file names.
			# @param pattern The file pattern to have excluded from the array of files.
			# @return Array of file names.
			def self.exclude_files(files, pattern)
				Dir.glob(pattern) do |file|
					files.delete file
				end

				return files
			end

			# Combine the specified files. If a block is specified then
			# the returned value from the block will be concatenated.
			#
			# The block should accept the file name and the file contents as a string.
			#
			# @param files Array of files to combine.
			# @return The files concatenated as a string.
			def self.combine(files, &block)
				content = ''

				files.each do |file|
					if File.exist? file and File.file? file
						file_content = File.read(file)

						if block
							content = content << block.call(file, file_content).to_s
						else
							content = content << file_content
						end
					end
				end

				return content
			end
		end
	end
end