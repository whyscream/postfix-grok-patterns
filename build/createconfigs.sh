#!/bin/bash

function pipelinepatterns {
    local tmpPatternComma=''
    while IFS="" read -r line || [ -n "$line" ]; do
        echo -ne "$tmpPatternComma"
        echo -n "$line" |sed -E -e 's/([^ ]+) (.*)/        "\1": "\2"/' -e 's/\\/\\\\/g'
        tmpPatternComma=",\n"
    done < "tmp/$1"
    echo
}

#####
##### Intros
#####

cat > '50-filter-postfix.conf' << 'EOT'
filter {
    # grok log lines by program name (listed alpabetically)
EOT

cat > 'pipeline.json' << 'EOT'
{
  "processors": [
EOT

#####
##### Groks for services
#####

tmpElse=''
for service in anvil bounce cleanup dnsblog error local master pickup pipe postdrop postscreen qmgr scache sendmail smtp lmtp smtpd postsuper tlsmgr tlsproxy trivial-rewrite discard virtual postmap postfix-script verify
do

    # special handling for postfix-script: remove "postfix-"
    serviceFixed="${service/postfix-/}"

    serviceFixedUppercase="${serviceFixed^^}"

cat >> '50-filter-postfix.conf' << EOT
    ${tmpElse}if [program] =~ /^postfix.*\/${service}$/ {
        grok {
            patterns_dir   => "/etc/logstash/patterns.d"
            match          => [ "message", "^%{POSTFIX_${serviceFixedUppercase//-/_}}$" ]
            tag_on_failure => [ "_grok_postfix_${serviceFixed//-/_}_nomatch" ]
            add_tag        => [ "_grok_postfix_success" ]
        }
EOT

cat >> 'pipeline.json' << EOT
  {
    "grok": {
      "field": "message",
      "patterns": [
        "^%{POSTFIX_${serviceFixedUppercase//-/_}}$"
      ],
      "pattern_definitions": {
EOT

pipelinepatterns "POSTFIX_${serviceFixedUppercase//-/_}.grok" >> 'pipeline.json'

cat >> 'pipeline.json' << EOT
      },
      "ignore_missing": true,
      "if": "ctx.process?.name != null && ctx.process.name.endsWith('/${service}')",
      "description": "${serviceFixedUppercase}",
      "on_failure": [
        {
          "append": {
            "field": "tags",
            "value": [
              "_grokparsefailure",
              "_grok_postfix_${serviceFixed}_nomatch"
            ],
            "allow_duplicates": false
          }
        }
      ]
    }
  },
EOT

    tmpElse='} else '
done

#####
##### Catchall tag
#####

# FIXME: Not sure how to do this in a Pipeline without `else if`

cat >> '50-filter-postfix.conf' << 'EOT'
    } else if [program] =~ /^postfix.*/ {
        mutate {
            add_tag => [ "_grok_postfix_program_nomatch" ]
        }
    }

EOT


#####
##### KV handling
#####

cat >> '50-filter-postfix.conf' << 'EOT'
    # process key-value data if it exists
    if [postfix_keyvalue_data] {
        kv {
            source       => "postfix_keyvalue_data"
            trim_value   => "<>,"
            prefix       => "postfix_"
            remove_field => [ "postfix_keyvalue_data" ]
        }

        # some post processing of key-value data
EOT

cat >> 'pipeline.json' << 'EOT'
  {
    "kv": {
      "field": "postfix_keyvalue_data",
      "field_split": " ",
      "value_split": "=",
      "ignore_missing": true,
      "prefix": "postfix_",
      "trim_value": "<>,"
    }
  },
  {
    "remove": {
      "field": "postfix_keyvalue_data",
      "ignore_missing": true
    }
  },
EOT

# FIXME these probably don't have to be inside of the KV `if` block,
#       they can't be nested in a pipeline anyway

tmpComma=''
for field in postfix_client postfix_relay postfix_delays
do
cat >> '50-filter-postfix.conf' << EOT
        if [${field}] {
            grok {
                patterns_dir   => "/etc/logstash/patterns.d"
                match          => ["${field}", "^%{${field^^}}$"]
                tag_on_failure => [ "_grok_kv_${field}_nomatch" ]
                remove_field   => [ "${field}" ]
            }
        }
EOT

    echo -e "${tmpComma}  {" >> 'pipeline.json'
cat >> 'pipeline.json' << EOT
    "grok": {
      "field": "${field}",
      "patterns": [
        "^%{${field^^}}$"
      ],
      "pattern_definitions": {
EOT
    pipelinepatterns "${field^^}.grok" >> 'pipeline.json'
cat >> 'pipeline.json' << EOT
      },
      "ignore_missing": true,
      "description": "${field}",
      "on_failure": [
        {
          "append": {
            "field": "tags",
            "value": [
              "_grok_kv_${field}_nomatch"
            ],
            "allow_duplicates": false
          }
        }
      ]
    }
  },
  {
    "remove": {
      "field": "${field}",
      "ignore_missing": true,
      "if": "ctx?.tags?.contains('_grok_kv_${field}_nomatch')==false",
      "description": "${field}"
    }
  },
EOT

done

cat >> '50-filter-postfix.conf' << EOT
    }

    # process command counter data if it exists
EOT

# FIXME this could be included in the above list if that wasn't nested
# but this would require changes in the tags field
field='postfix_command_counter_data'
cat >> '50-filter-postfix.conf' << EOT
    if [${field}] {
        grok {
            patterns_dir   => "/etc/logstash/patterns.d"
            match          => ["${field}", "^%{${field^^}}$"]
            tag_on_failure => ["_grok_${field}_nomatch"]
            remove_field   => ["${field}"]
        }
    }

EOT

cat >> 'pipeline.json' << EOT
  {
    "grok": {
      "field": "${field}",
      "patterns": [
        "^%{${field^^}}$"
      ],
      "pattern_definitions": {
EOT
    pipelinepatterns "${field^^}.grok" >> 'pipeline.json'
cat >> 'pipeline.json' << EOT
      },
      "ignore_missing": true,
      "description": "${field}",
      "on_failure": [
        {
          "append": {
            "field": "tags",
            "value": [
              "_grok_${field}_nomatch"
            ],
            "allow_duplicates": false
          }
        }
      ]
    }
  },
  {
    "remove": {
      "field": "${field}",
      "ignore_missing": true,
      "if": "ctx?.tags?.contains('_grok_${field}_nomatch')==false",
      "description": "${field}"
    }
  },
EOT

#####
##### Conversions
#####

cat >> '50-filter-postfix.conf' << 'EOT'
    # Do some data type conversions
    mutate {
        convert => [
            # list of integer fields
EOT

##### Integer fields

tmpComma=''
for field in anvil_cache_size anvil_conn_count anvil_conn_rate client_port cmd_auth cmd_auth_accepted cmd_bdat cmd_bdat_accepted cmd_count cmd_count_accepted cmd_data cmd_data_accepted cmd_ehlo cmd_ehlo_accepted cmd_helo cmd_helo_accepted cmd_mail cmd_mail_accepted cmd_noop cmd_noop_accepted cmd_quit cmd_quit_accepted cmd_rcpt cmd_rcpt_accepted cmd_rset cmd_rset_accepted cmd_starttls cmd_starttls_accepted cmd_unknown cmd_unknown_accepted nrcpt postscreen_cache_dropped postscreen_cache_retained postscreen_dnsbl_rank relay_port server_port size status_code termination_signal tls_server_signature_size verify_cache_dropped verify_cache_retained
do
    echo -ne "${tmpComma}            \"postfix_${field}\", \"integer\"" >> '50-filter-postfix.conf'

    echo -e "${tmpComma}  {" >> 'pipeline.json'
cat >> 'pipeline.json' << EOT
    "convert": {
      "field": "postfix_${field}",
      "type": "integer",
      "ignore_missing": true
    }
EOT
    echo -n "  }" >> 'pipeline.json'

    tmpComma=",\n"
done

echo -e "$tmpComma\n            # list of float fields" >> '50-filter-postfix.conf'
echo -ne "$tmpComma" >> 'pipeline.json'

##### Float fields

tmpComma=''
for field in delay delay_before_qmgr delay_conn_setup delay_in_qmgr delay_transmission postscreen_violation_time
do
    echo -ne "${tmpComma}            \"postfix_${field}\", \"float\"" >> '50-filter-postfix.conf'

    echo -e "${tmpComma}  {" >> 'pipeline.json'
cat >> 'pipeline.json' << EOT
    "convert": {
      "field": "postfix_${field}",
      "type": "float",
      "ignore_missing": true
    }
EOT
    echo -n "  }" >> 'pipeline.json'

    tmpComma=",\n"
done

##### Outros

cat >> '50-filter-postfix.conf' << 'EOT'

        ]
    }
}

EOT

echo  -e "\n]\n}" >> 'pipeline.json'
