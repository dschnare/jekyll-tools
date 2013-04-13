# Default/stub copy hook file. This hook file will only act as a pass through.

require 'fileutils'

# Copies a source file to a destination.
#
# @param [String] source_file The file path of the source file.
# @param [String] dest_file The file path of the destination file.
# @param [Hash] settings The settings for the tool.
def copy_file(source_file, dest_file, settings)
	FileUtils.cp_r(source_file, dest_file)
end