module Jekyll
	module Tools
		# Class that will manage all hook files. Adding a hook file to an instance of this class
		# will enqueue the hook file so that new hooks are searched first when calling a hook.
		#
		# A hook is simply a function within a hook file.
		class Hooks
			@@hooks = {}
			attr_reader :hook_file

			def initialize(hooks_file, parent=nil)
				@hooks_file = hooks_file
				@parent = parent
			end

			# Determines if a hook can be called.
			#
			# @param hook The hook name as a string.
			def can_call_hook?(hook)
				result = false

				begin
					hooks = get_hooks()
					result = true if hooks.respond_to?(hook.to_sym)
				rescue
					result = false
				end

				if !result and !@parent.nil?
					result = @parent.can_call_hook?(hook)
				end

				result
			end

			# Will attempt to call a hook with the specified arguments.
			#
			# If a block is given and no hook can be found then the block will
			# be called (i.e. the block will be the fallback).
			#
			# @param hook The hook name as a string.
			# @param *args The arguments to be passed to the hook.
			# @return The result of calling the hook or the block if a hook does not exist.
			def call_hook(hook, *args, &block)
				result = nil
				method = nil

				hooks = get_hooks()
				method = hooks.method(hook) if hooks.respond_to?(hook.to_sym)

				if method
					result = method.call(*args)
				elsif !@parent.nil?
					return @parent.call_hook(hook, *args, &block)
				end

				if result.nil? and block_given?
					result = yield *args
				end

				result
			end


			private

			def get_hooks()
				if @hooks_file.nil?
					hooks = Class.new
					hooks.new
				elsif @@hooks.has_key?(@hooks_file)
					@@hooks[@hooks_file]
				else
					script = File.read(@hooks_file)
					hooks = Class.new
					hooks.class_eval(script)
					@@hooks[@hooks_file] = hooks.new
				end
			end
		end
	end
end