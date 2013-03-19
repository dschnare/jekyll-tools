# Requires the settings key 'tsc' to point to the TypeScript JavaScript compiler.
# Requires Nodejs to be installed.

require 'fileutils'
require 'tempfile'

def compile(js, settings)
	# The TypeScript compiler requires a file for input and it will write
	# the JavaScript with the same name next to the source .ts file.
	# So we must create a temporary .ts file so we can compile it.
	tsc = settings['tsc']
	file = Tempfile.new(['typescript', '.ts'])
	file.write(js)
	file.close

	error = `node "#{tsc}" #{file.path}`

	# The .js file path.
	jsfile = File.join(File.dirname(file.path), File.basename(file.path, '.ts')) << '.js'
	file.delete

	# If the .js file exists then we read it and return its contents.
	if File.exist?(jsfile)
		js = File.read(jsfile)
		File.delete(jsfile)
		js
	else
		error
	end
end