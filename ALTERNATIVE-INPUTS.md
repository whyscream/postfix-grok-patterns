Adapt alternative inputs
========================

Various other input file can produce the needed input fields (`program` and `message`) for the postfix grok patterns too, with a little help. You can simply include the lines listed below in a file named `49-filter-postfix-prepare.conf` (or something else to your liking, as long as it's alphabetically listed before the `50-filter-postfix.conf` file).

[Beats/Filebeat](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-beats.html)
----------------

``` 
grok {
    match => { "message" => "%{SYSLOGTIMESTAMP} %{SYSLOGHOST} %{DATA:program}(?:\[%{POSINT}\])?: %{GREEDYDATA}" }
}
```

