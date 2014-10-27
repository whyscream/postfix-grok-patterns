require 'rubygems'
require 'minitest/autorun'
require 'grok-pure'
require 'yaml'

class TestGrokPatterns < MiniTest::Unit::TestCase

    def setup
        @test_dir = File.dirname(__FILE__)
        upstream_patterns = "/opt/logstash/patterns/"
        postfix_patterns = File.expand_path(@test_dir + "/../postfix-patterns.conf")

        @grok = Grok.new
        Dir.new(upstream_patterns).each do |file|
            next if file =~ /^\./
            @grok.add_patterns_from_file(upstream_patterns + file)
        end
        @grok.add_patterns_from_file(postfix_patterns)
    end

    def test_pattern
        Dir.new(File.dirname(__FILE__)).each do |file|
            if file =~ /\.log$/
                pattern = File.basename(file, ".log")
                @grok.compile("%{" + pattern +"}")

                File.open(File.expand_path(@test_dir + "/" + file)).each do |line|
                    # skip comments in log files
                    next if line =~ /^#/
                    assert @grok.match(line), "Grok failure using pattern #{pattern} for line: #{line}"
                end
            end
        end
    end

    def test_grok_pattern
        Dir.new(@test_dir).each do |file|
            if file =~ /\.yaml$/
                config = YAML.load(File.read(File.expand_path(@test_dir + "/" + file)))

                assert @grok.compile("%{" + config['pattern'] + "}", true)
                captures = @grok.match(config['logline']).captures()

                next if config['results'].nil?
                config['results'].each do |field, expected|
                    assert_includes captures.keys, field
                    assert_includes captures[field], expected.to_s
                end
            end
        end
    end
end
