require 'rubygems'
require 'minitest/autorun'
require 'grok-pure'
require 'yaml'

# Test suite runner for grok patterns
#
# Author:: Tom Hendrikx <tom@whyscream.net>
# License:: New (3-clause) BSD license

# This class tests grok patterns, mainly known from logstash.
# It creates test cases from all yaml files in the current
# directory.

class TestGrokPatterns < MiniTest::Unit::TestCase

    @@test_dir = File.dirname(__FILE__)
    @@upstream_pattern_dir = @@test_dir + '/logstash/patterns'
    @@postfix_pattern_file = File.dirname(File.expand_path(@@test_dir)) + '/postfix-patterns.conf'

    # Prepare a grok object.
    #
    # Adds the available upstream and local grok pattern files to
    # a new grok object, so it's ready for being used in a test.
    def setup
        @grok = Grok.new
        Dir.new(@@upstream_pattern_dir).each do |file|
            next if file =~ /^\./
            @grok.add_patterns_from_file(@@upstream_pattern_dir + '/' + file)
        end
        @grok.add_patterns_from_file(@@postfix_pattern_file)
    end

    # Test a grok pattern.
    #
    # The following things are checked:
    # - the given pattern name can be compiled using the grok regex library
    # - the given data can be parsed using the pattern
    # - the given results actually appear in the regex captures.
    #
    # Arguments:
    # pattern:: A pattern name that occurs in the loaded pattern files
    # data:: Input data that should be grokked, f.i. a log line
    # results:: A list of named captures and their expected contents
    def grok_pattern_tester(pattern, data, results)
        assert @grok.compile("%{" + pattern + "}", true)
        captures = @grok.match(data).captures()

        return if results.nil?
        results.each do |field, expected|
            assert_includes captures.keys, field
            assert_includes captures[field], expected.to_s
        end
    end

    # collect all tests
    tests = Hash.new()
    Dir.new(@@test_dir).each do |file|
        next if file !~ /\.yaml$/
        test = File.basename(file, '.yaml')
        conf = YAML.load(File.read(@@test_dir + '/' + file))
        tests[test] = conf
    end

    # define test methods for all collected tests
    tests.each do |name, conf|
        define_method("test_#{name}") do
            grok_pattern_tester(conf['pattern'], conf['data'], conf['results'])
        end
    end
end
