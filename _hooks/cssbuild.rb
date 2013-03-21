# Default/stub cssbuild hook file. This hook file will only act as a pass through
# and only included for the purpose of documentation.

# Called just before compiling. This hook can modify the main
# stylesheet before compilation. Any changes must be saved to the
# stylesheet file.
#
# @pram [String] main_file The file path to the main stylesheet.
# @param [Hash] settings The settings for the tool.
# @return [String] The contents of the main stylesheet.
def pre_compile(main_file, settings)
	File.read(main_file)
end

# Compiles the main stylesheet.
#
# @pram [String] css The loaded main stylesheet.
# @pram [Array] include_paths All directories to set as an include path.
# @param [Hash] settings The settings for the tool.
# @return [String] The compiled result.
def compile(css, include_paths, settings)
	css
end

# Called after compilation. This hook can modify the compiled CSS.
#
# @pram [String] css The compiled CSS.
# @param [Hash] settings The settings for the tool.
# @return [String] The modified compiled CSS.
def post_compile(css, settings)
	css
end