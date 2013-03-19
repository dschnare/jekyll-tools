require 'fileutils'

# Copies a source file to a destination.
#
# @param [String] source_file The file path of the source file.
# @param [String] dest_file The file path of the destination file.
def copy_file(source_file, dest_file)
	FileUtils.cp_r(source_file, dest_file)
end