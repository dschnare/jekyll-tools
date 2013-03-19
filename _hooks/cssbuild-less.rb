# Requires the settings key 'lessc' to point to the Less JavaScript compiler.
# Requires Nodejs to be installed.

require 'open3'

# Compiles the main stylesheet. Note that all LESS stylesheets 
# included in the main stylesheet will be relative to the main_file.
def compile(main_file, include_paths, settings)
	lessjs = settings['lessc']
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