# Hooks for the jsbuild tool that will compile CoffeeScript files.
# Requires the settings key 'coffee' to point to the CoffeeScript JavaScript compiler.
# Requires Nodejs to be installed.

require 'open3'

def compile(js, settings)
	coffee = settings['coffee']
	command = "node #{coffee} -sc"
	result = js

	begin
		Open3.popen3(command) do |stdin, stdout, stderr|
			stdin.puts(js)
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

	return result
end