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

class TestGrokPatterns < MiniTest::Test

    @@test_dir = File.dirname(__FILE__)
    @@upstream_pattern_dir = @@test_dir + '/logstash-patterns-core/patterns/ecs-v1/'
    @@local_pattern_dir = File.dirname(File.expand_path(@@test_dir))

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
        Dir.new(@@local_pattern_dir).each do |file|
            next if file !~ /\.grok$/
            @grok.add_patterns_from_file(@@local_pattern_dir + '/' + file)
        end
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
        assert @grok.compile(pattern, true), "Failed to compile pattern #{pattern}"
        assert matches = @grok.match(data), "Pattern #{pattern} did not match data."

        refute_equal results, nil, "Test case is flawed, no results are defined"
        captures = matches.captures()
        results.each do |field, expected|
            assert_includes captures.keys, field
            assert_includes captures[field], expected.to_s, "Missing expected data in field '#{field}'"
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
