require 'fileutils'

class Hash
	def get(key, default)
		return self[key] if has_key? key
		return default
	end

	def get_as_array(key)
		if has_key? key
			value = self[key]
			return value.kind_of?(Array) ? value : [value]
		end

		return []
	end
end


module FileHelpers
	def self.get_files(incl, excl)
		files = []

		incl.each do |pattern|
			files = files.concat(Dir.glob(pattern))
		end

		excl.each do |pattern|
			exclude_files(files, pattern)
		end

		files
	end

	def self.exclude_files(files, pattern)
		Dir.glob(pattern) do |file|
			files.delete file
		end

		return files
	end

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