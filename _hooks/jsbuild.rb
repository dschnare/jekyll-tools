# Requires the 'uglifier' gem to be installed.

require 'uglifier'

# Mutates the contents of a file before combining.
#
# @param [String] file The file path of the loaded Javascript file.
# @param [String] file_content The file contents of the Javascript file.
# @param [Hash] settings The settings for the tool.
# @return [String] The contents of the loaded Javascript file.
def pre_combine_file(file, file_content, settings)
	file_content
end

# Mutates the contents of the combined Javascript file before being compiled.
#
# @param [String] js The contents of the combined Javascript file.
# @param [Hash] settings The settings for the tool.
# @return [String] The contents of the combined Javascript file.
def pre_compile(js, settings)
	js
end

# Compiles the combined Javascript file.
#
# @param [Striing] js The contents of the combined Javascript file.
# @param [Hash] settings The settings for the tool.
# @return [String] The compiled Javascript.
def compile(js, settings)
	Uglifier.new.compile js
end

# Mutates the contents of the compiled Javascript file after being compiled.
#
# @param [String] js The contents of the compiled Javascript file.
# @param [Hash] settings The settings for the tool.
# @return [String] The contents of the compiled Javascript file.
def post_compile(js, settings)
	js
end