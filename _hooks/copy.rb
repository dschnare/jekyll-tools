# NOTE: This file has a .hook extension so Jekyll won't load it as a Ruby file.
# You can use any extension you want for your hooks so long as the hook file is a valid Ruby script.

require 'fileutils'

# Copies a source file to a destination.
#
# @param [String] source_file The file path of the source file.
# @param [String] dest_file The file path of the destination file.
def copy_file(source_file, dest_file)
	FileUtils.cp_r(source_file, dest_file)
end