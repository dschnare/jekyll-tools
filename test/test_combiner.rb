# Note: Invoke this test by executing `rake`

require "yaml"
require "fileutils"
require "test/unit"

require_relative "jekyll_mock"
require_relative "../combiner"

class TestCombiner < Test::Unit::TestCase
	def setup
		if File.exist? "gen"
			FileUtils.rm_rf "gen"
		end
	end

	def teardown
		if File.exist? "gen"
			FileUtils.rm_rf "gen"
		end
	end

	def combine(config)
		Jekyll::CombinerGenerator.new().generate(Jekyll::Site.new(YAML.load(config)))
	end

	####################
	# LESS
	####################

	def test_less_combine
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  less:
    command: 'node lib/lessjs/bin/lessc --include-path=:tmp -'
    compile:
    - in: ['css/*.less']
      out: 'gen/combined.css'
      root: 'main.less'
EOS
		combine config
		assert_true File.exist?("gen/combined.css")
		assert File.read("gen/combined.css").index(".test") >= 0
	end

	def test_less_combine_min
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  less:
    command: 'node lib/lessjs/bin/lessc --compress --include-path=:tmp -'
    compile:
    - in: ['css/*.less']
      out: 'gen/combined.min.css'
      root: 'main.less'
EOS
		combine config
		assert_true File.exist?("gen/combined.min.css")
		assert File.read("gen/combined.min.css").index(".test") >= 0
	end

	def test_less_combine_exclude
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  less:
    command: 'node lib/lessjs/bin/lessc --include-path=:tmp -'
    compile:
    - in: ['css/*.less']
      not: 'test'
      out: 'gen/combined.css'
      root: 'main.less'
EOS
		combine config
		assert_true File.exist?("gen/combined.css")
		assert_equal File.read("gen/combined.css").index(".test"), nil
	end

	def test_less_combine_hash
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  less:
    command: 'node lib/lessjs/bin/lessc --include-path=:tmp -'
    compile:
    - in: ['css/*.less']
      out: 'gen/combined_:hash.css'
      hash: 'gen/hash_css.txt'
      root: 'main.less'
EOS
		combine config
		assert_true File.exist?("gen/hash_css.txt")
		hash = File.read("gen/hash_css.txt")
		assert_true File.exist?("gen/combined_#{hash}.css")
		assert File.read("gen/combined_#{hash}.css").index(".test") >= 0
	end

	####################
	# JS
	####################

	def test_js_combine
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  js:
    combine:
    - in: ['js/test.js', 'js/test2.js']
      out: 'gen/combined.js'
EOS
		combine config
		assert_true File.exist?("gen/combined.js")
		assert File.read("gen/combined.js").index("test =") >= 0
	end

	def test_js_combine_min
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  js:
    combine:
    - in: ['js/test.js', 'js/test2.js']
      out: 'gen/combined.min.js'
      uglify: true
EOS
		combine config
		assert_true File.exist?("gen/combined.min.js")
		assert File.read("gen/combined.min.js").index("test=") >= 0
	end

	def test_js_combine_exclude
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  js:
    combine:
    - in: ['js/test.js', 'js/test2.js']
      not: 'test2'
      out: 'gen/combined.js'
EOS
		combine config
		assert_true File.exist?("gen/combined.js")
		assert_equal File.read("gen/combined.js").index("test2 ="), nil
	end

	def test_js_combine_hash
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  js:
    combine:
    - in: ['js/test.js', 'js/test2.js']
      out: 'gen/combined_:hash.js'
      hash: 'gen/hash_js.txt'
EOS
		combine config
		assert_true File.exist?("gen/hash_js.txt")
		hash = File.read("gen/hash_js.txt")
		assert_true File.exist?("gen/combined_#{hash}.js")
		assert File.read("gen/combined_#{hash}.js").index("test =") >= 0
	end

	####################
	# COPY
	####################

	def test_img_copy
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  copy:
  - in: ['img/*.jpg', 'img/*.png']
    out: 'gen'
EOS
		combine config
		assert_true File.exist?("gen/test.jpg")
		assert_true File.exist?("gen/test.png")
		assert_false File.exist?("gen/test.gif")
	end

	def test_img_copy_exclude
		config = <<EOS
combiner:
  tmp: tmp
  silent: true
  copy:
  - in: ['img/*.*']
    not: ['.jpg', '.png']
    out: 'gen'
EOS
		combine config
		assert_false File.exist?("gen/test.jpg")
		assert_false File.exist?("gen/test.png")
		assert_true File.exist?("gen/test.gif")
	end
end