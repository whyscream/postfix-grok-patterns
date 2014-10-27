Logstash grok patterns for postfix logging
==========================================

A set of grok patterns for parsing postfix logging using grok. Also included is a sample Logstash config file for applying the grok patterns as a filter.

Usage
-----

- Install logstash
- Add `filter-postfix.conf` to `/etc/logstash/conf.d`
- Add `postfix-patterns.conf` to `/etc/logstash/patterns.d`
- Restart logstash

The included Logstash config file expects the postfix log data in the `message` field, something that works out of the box when you use Logstash's `syslog` input to receive postfix logging.

Tests
-----

In the `test/` directory, there is a minimal test suite that tries to make sure that no previously supported log line will break because of changing common patterns and such. It also returns results a lot faster than doing `sudo service logstash restart` :-).

To run the test suite, you need `ruby 1.9` and the `jls-grok` gem. Then simply execute `ruby test/test.rb`. 

Adding new test cases can easily be done by creating new yaml files in the test directory. Each file specififes a grok pattern to validate, a sample log line, and a list of expected results.

Also, the example Logstash config file adds some informative tags that aid in finding grok failures and unparsed lines. If you're not interested in those, you can remove all occurrences of `add_tag` and `tag_on_failure` from the config file.

Contributing
------------

I only have access to my own log samples, and my setup does not support or use every feature in postfix. If you miss anything, please do a pull request on github. If you're not very well versed in regular expressions, it's also fine to only submit sample unsupported log lines.

License
-------

Everything in this repository is available under the New (3-clause) BSD license.

Acknowledgement
---------------
I use postfix (2.11), logstash (1.4.2), elasticsearch (1.4.0-beta1) and kibana (3.1.3) in order to get everything working.
For writing the grok patterns I depend heavily on [grokdebug](https://grokdebug.herokuapp.com/), and I looked a lot at [antispin's useful logstash grok patterns](http://antisp.in/2014/04/useful-logstash-grok-patterns/).
