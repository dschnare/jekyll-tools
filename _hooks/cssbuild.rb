# Default/stub cssbuild hook file. This hook file will only act as a pass through
# and only included for the purpose of documentation.

# Called just before compiling. This hook can modify the main
# stylesheet before compilation. Any changes must be saved to the
# stylesheet file.
#
# @pram [String] main_file The file path to the main stylesheet.
# @param [Hash] settings The settings for the tool.
def pre_compile(main_file, settings)
	main_file
end

# Compiles the main stylesheet.
#
# @pram [String] main_file The file path to the main LESS stylesheet.
# @pram [String] include_paths All directories to set as an include path. Format <path>:<path>:<path>...
# @param [Hash] settings The settings for the tool.
# @return [String] The compiled result.
def compile(main_file, include_paths, settings)
	main_file
end

# Called after compilation. This hook can modify the compiled CSS.
#
# @pram [String] css The compiled CSS.
# @param [Hash] settings The settings for the tool.
# @return [String] The modified compiled CSS.
def post_compile(css, settings)
	css
end