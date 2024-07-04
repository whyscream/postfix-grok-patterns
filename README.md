Logstash grok patterns for postfix logging
==========================================

A set of grok patterns for parsing postfix logging using grok. Also included is a sample Logstash config file for applying the grok patterns as a filter.

Usage
-----

- Install logstash
- Add `50-filter-postfix.conf` to `/etc/logstash/conf.d` or `pipeline` dir for dockerized Logstash
- Make dir `/etc/logstash/patterns.d`
- Add `postfix.grok` to `/etc/logstash/patterns.d`
- Restart logstash

The included Logstash config file requires two input fields to exist in input events:

- `program`: the name of the program that generated the log line, f.i. `postfix/smtpd` (named `tag` in syslog lingo)
- `message`: the log message payload without additional fields (program, pid, etc), f.i. `connect from 1234.static.ctinets.com[45.238.241.123]`

This event format is supported by the Logstash `syslog` input plugin out of the box, but several other plugins produce input that can be adapted fairly easy to produce these fields too. See [ALTERNATIVE INPUTS](ALTERNATIVE-INPUTS.md) for details.

Tests
-----

In the `test/` directory, there is a test suite that tries to make sure that no previously supported log line will break because of changing common patterns and such. It also returns results a lot faster than doing `sudo service logstash restart` :-).

The test suite needs the patterns provided by Logstash, you can easily pull these from github by running `git submodule update --init`. To run the test suite, you need a recent version of `ruby` (`2.6` or newer should work), and the `jls-grok` and `minitest` gems. Then simply execute `ruby test/test.rb`. NOTE: The whole test process can now be executed inside a docker container, simply by running the `test_grok_patterns.sh` script.

Adding new test cases can easily be done by creating new yaml files in the test directory. Each file specifies a grok pattern to validate, a sample log line, and a list of expected results.

Also, the example Logstash config file adds some informative tags that aid in finding grok failures and unparsed lines. If you're not interested in those, you can remove all occurrences of `add_tag` and `tag_on_failure` from the config file.

Additional test scripts are available for local tests (using docker containers):
- `test_grok_patterns.sh`: runs the test suite for the grok patterns in `postfix.grok`
- `test_logstash_config.sh`: validates the logstash config in `50-filter-postfix.conf`
- `test_pipeline.sh`: validates that the logstash config can be used in a simple logstash pipeline, and ensures that this results in parsed messages

Contributing
------------

I only have access to my own log samples, and my setup does not support or use every feature in postfix. If you miss anything, please open a pull request on github. If you're not very well versed in regular expressions, it's also fine to only submit sample unsupported log lines.

Other guidelines:
- There is no goal to parse every possible Postfix log line. The goal is to extract useful data from the logs in a generic way.
- The target for data extraction is logging from a local server. There have been requests to parse SMTP replies from remote (Postfix) servers that are logged by the SMTP client (`postfix/smtp` program name). There is no way to parse these replies in a generic way, they differ from implementation to implementation (f.i. Postfix vs Exim) and from server to server (every admin can customize the message format). Parsing stock replies from remote Postfix servers could be done, but would be confusing since the messages don't originate from the local server. Requests for parsing these are not honoured. If you like to do that, implement it yourself, or start a separate project, I'd be happy to add a link to it. :)

License
-------

Everything in this repository is available under the New (3-clause) BSD license. See ![LICENSE](LICENSE) for details.

Acknowledgement
---------------
I use postfix, logstash, elasticsearch and kibana in order to get everything working.
For writing the grok patterns I depend heavily on [grokdebug](https://grokdebug.herokuapp.com/), and I looked a lot at [antispin's useful logstash grok patterns](http://antisp.in/2014/04/useful-logstash-grok-patterns/).
