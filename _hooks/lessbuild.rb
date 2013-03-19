# NOTE: This file has a .hook extension so Jekyll won't load it as a Ruby file.
# You can use any extension you want for your hooks so long as the hook file is a valid Ruby script.

# Requires lessjs to be available at '_assets/node_modules/less/bin/lessc'
# Requires Nodejs to be installed.

require 'open3'

# Called just before compiling. This hook can modify the main LESS
# stylesheet before compilation. Any changes must be saved to the
# main LESS file.
#
# @pram [String] main_file The file path to the main LESS stylesheet.
def pre_compile(main_file)
	# do nothing to the main file
end

# Compiles the main LESS stylesheet and any imported LESS stylesheets.
# Note that all LESS stylesheets included in this build target will be in the
# same directory as main_file.
#
# @pram [String] main_file The file path to the main LESS stylesheet.
# @pram [String] include_paths All directories to set as an include path. Format <path>:<path>:<path>...
# @return [String] The compiled result.
def compile(main_file, include_paths)
	lessjs = '_assets/node_modules/less/bin/lessc'
	content = File.read(main_file)
	result = content
	command = "node \"#{lessjs}\" --compress --include-path=\"#{include_paths}\" -"

	begin
		Open3.popen3(command) do |stdin, stdout, stderr|
			stdin.puts(content)
			stdin.close
			result = stdout.read
			error = stderr.read
			stdout.close
			stderr.close

			if error.length > 0
				puts error
			end
		end
	end

	result
end

# Called after compilation. This hook can modify the compiled CSS.
#
# @pram [String] css The compiled CSS.
# @return [String] The modified compiled CSS.
def post_compile(css)
	css
end