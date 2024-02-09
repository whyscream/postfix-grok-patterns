# Logstash config and Kibana Pipeline build script

This script is used to generate a `50-filter-postfix.conf` file for Logstash and a corresponding `pipeline.json` to be used as an Ingest pipeline in Kibana.

It was written to make it easier to keep the two environments similar when updating the patterns or configuration.

One big issue with Kibana pipelines is that you'd have to upgrade the custom grok patterns in each processor individually. Adding the full set of `postfix.grok` patterns to each processor felt wrong too. So I tried to find a way that only adds the necessary patterns.

The Ingest pipelines are also a little different than the Logstash filters. For example the grok processor does not remove fields or can set a tag on success.

## Requirements
- bash 4.0 to allow some modern string-variable handling
- cut, grep, sed, cmp as general shell tools

## Usage

1. Run `bash splitpatterns.sh`. This will create a temporary folder and use some shell tool magic to loop through `../postfix.grok` recursively so it can create a file for each grok pattern that includes all its required subpatterns.
2. Run `bash createconfigs.sh` to create the `50-filter-postfix.conf` and `pipeline.json` files.
3. Use these files as needed


## TODO
- Should the `splitpatterns.sh` script be called from the `createconfigs.sh` instead of being run manually in advance? This would allow cleaning up the `tmp` folder too.
- Document how to "load" and use the `pipeline.json` into Kibana in the main `README.md`. (see "Hints")
- Make the scripts easier readable?
- Convert IP fields?
- Add processor to run a `whyscreem-postfix@custom` pipeline after if people want to mangle with the fields themselves (GeoIP referencing, renaming to local specifications, ...)?
- Add a version number to the pipeline?
- Find a way to set `_grok_postfix_program_nomatch` as a catchall tag for the pipeline. Without `else if` this might not be possible.
- Move `postfix_client`, `postfix_relay` and `postfix_delays` out of the "kv" block. Pipelines don't allow this nesting?

## Hints

1. Load the `pipeline.json` file into elasticsearch:
```
curl -k -H "Content-Type: application/json" -T pipeline.json "/_ingest/pipeline/whyscream-postfix"
```

Additional parameters like `-H "Authorization: ApiKey ..." or `-u user:pass` might be needed just as protocol, hostname and port: `https://localhost:9200`.

Then call this pipeline where needed.
