=begin

Class that will manage all hook files. Adding a hook file to an instance of this class
will enqueue the hook file so that newew hooks files are searched first when calling a hook.

=end
class Hooks
	@@hooks = {}

	def initialize
		@hook_files = []
	end

	def add_hooks(hook_file)
		if hook_file.kind_of?(String) and File.exist?(hook_file)
			@hook_files.unshift(hook_file)
		end
	end

	def <<(hook_file)
		add_hooks(hook_file)
	end

	def can_call_hook?(hook)
		result = false

		@hook_files.each do |hook_file|
			begin
				hooks = get_hooks(hook_file)
				result = true if hooks.respond_to?(hook.to_sym)
				break
			rescue
				result = false
			end
		end

		result
	end

	# If a block is given and no hook can be found then
	# the block will be called (i.e. the block will be the fallback).
	def call_hook(hook, *args)
		result = nil
		method = nil

		@hook_files.each do |hook_file|
			hooks = get_hooks(hook_file)
			method = hooks.method(hook) if hooks.respond_to?(hook.to_sym)

			if method
				result = method.call(*args)
				break
			end
		end

		if result.nil? and block_given?
			result = yield *args
		end

		result
	end

	private

	def get_hooks(hook_file)
		if @@hooks.has_key?(hook_file)
			@@hooks[hook_file]
		else
			script = File.read(hook_file)
			hooks = Class.new
			hooks.class_eval(script)
			@@hooks[hook_file] = hooks.new
		end
	end
end