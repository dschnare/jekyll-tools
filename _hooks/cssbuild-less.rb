# Hooks for the cssbuild tool that compiles LESS stylesheets. The output is minified.
# Requires the settings key 'lessc' to point to the Less JavaScript compiler.
# Requires Nodejs to be installed.

require 'open3'
require 'os'

# Compiles the main stylesheet. Note that all LESS stylesheets 
# included in the main stylesheet will be relative to the main_file.
def compile(css, include_paths, settings)
	lessjs = settings['lessc']
	result = css
	sep = (OS.windows? or OS::Underlying.windows?) ? ';' : ':'
	command = "node \"#{lessjs}\" --compress --include-path=\"#{include_paths.join(sep)}\" -"

	begin
		Open3.popen3(command) do |stdin, stdout, stderr|
			stdin.puts(css)
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