#!/bin/bash

# Admin API key from your account settings

adminAPIKey=$(echo "$ADMINAPIKEY")
# Other attributes found at https://docs.newrelic.com/docs/apis/synthetics-rest-api/monitor-examples/attributes-synthetics-rest-api#api-attributes
monitorName=$(echo "$K8SAPPNAME")
monitorType='SCRIPT_API'
frequency=10
locations='"AWS_US_WEST_1", "AWS_US_EAST_1"'
slaThreshold=1.0
# Location of the file with your script
SCRIPT=$(cat <<EOF 

var request = require("request");
var options = { method: 'GET',
  url: 'https://api.core.prod.servicebench.com$K8SCHECKPATH',
  headers: 
   { 'cache-control': 'no-cache',
     Connection: 'keep-alive',
     'accept-encoding': 'gzip, deflate',
     Host: 'api.core.prod.servicebench.com',
     'Postman-Token': '9b7d5cf0-7b87-42e1-8472-b0897ff4401b,2cd03df0-314f-4109-b115-1002e3ce9dba',
     'Cache-Control': 'no-cache',
     Accept: '*/*',
     'User-Agent': 'PostmanRuntime/7.11.0',
     'x-api-key': \$secure.APIKEY } };

request(options, function (error, response, body) {
  if (error) throw new Error(error);

  console.log(body);
});
EOF
)

  payload="{  \"name\" : \"$monitorName\", \"frequency\" : $frequency,    \"locations\" : [ $locations ],   \"status\" : \"ENABLED\",  \"type\" : \"$monitorType\", \"slaThreshold\" : $slaThreshold, \"uri\":\"\"}"
  echo "Creating monitor"

  # Make cURL call to API and parse response headers to get monitor UUID
  shopt -s extglob # Required to trim whitespace; see below
  while IFS=':' read key value; do
    # trim whitespace in "value"
    value=${value##+([[:space:]])}; value=${value%%+([[:space:]])}
    case "$key" in
        location) LOCATION="$value"
                ;;
        HTTP*) read PROTO STATUS MSG <<< "$key{$value:+:$value}"
                ;;
    esac
  done < <(curl -sS -i  -X POST -H "X-Api-Key:$adminAPIKey" -H 'Content-Type: application/json' https://synthetics.newrelic.com/synthetics/api/v3/monitors -d "$payload")

  # Validate monitor creation & add script unless it failed
  if [ $STATUS = 201 ]; then
    echo "Monitor created, $LOCATION "
    echo "Uploading script"
      # base64 encode script
      encoded=`echo "$SCRIPT" | base64 -w 0`
      scriptPayload='{"scriptText":"'$encoded'"}'
        curl -s -X PUT -H "X-Api-Key:$adminAPIKey" -H 'Content-Type: application/json' "$LOCATION/script" -d $scriptPayload
        echo "Script uploaded"
  else
    echo "Monitor creation failed"
  fi

echo "Creating Alert Condition"

monitorid=$(curl -H "X-Api-Key:$adminAPIKey" https://synthetics.newrelic.com/synthetics/api/v3/monitors | jq -r --arg monitorName "$monitorName" '. | .monitors[] |select(.name==$monitorName)|.id')
synthetic=$(cat << EOF
{
  "synthetics_condition": {
    "name": "$monitorName",
    "monitor_id": "$monitorid",
    "enabled": true
  }
}
EOF
)
curl -X POST 'https://api.newrelic.com/v2/alerts_synthetics_conditions/policies/444417.json' -H "X-Api-Key:$adminAPIKey" -i -H 'Content-Type: application/json' -d "$synthetic"
