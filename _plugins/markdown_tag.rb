module Jekyll
	class MarkdownTag < Liquid::Block
		def initialize(tag_name, markup, tokens)
			super
		end

		def render(context)
			raw_markdown_text = super(context)

			if raw_markdown_text.is_a? Array
				raw_markdown_text = raw_markdown_text[0].to_s
			else
				raw_markdown_text = raw_markdown_text.to_s
			end

			first_line = raw_markdown_text.split("\n").at(1)
			if first_line.nil?
				count = 0
			else
				match = first_line.match(/^([\t ]+)/)
				count = match.nil? ? 0 : match[0].length
			end

			markdown_text = raw_markdown_text.gsub(/^[\t ]{#{count}}/m, '')

			site = context.registers[:site]
			converter = site.getConverterImpl(Jekyll::Converters::Markdown)
			result = converter.convert(markdown_text)

			return result

			#if raw_markdown_text.include?('## Executive Team')
				#puts markdown_text
				#puts converter.convert(markdown_text)
				#puts "|" + match[0] + "|"
				#puts "count: " + count.to_s
			#end
		end
	end
end

Liquid::Template.register_tag('markdown', Jekyll::MarkdownTag)