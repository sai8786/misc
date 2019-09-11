#!/bin/bash
# This script is used to mark the deployment marker on the APM in NewRElic.
#This script is part of DeploymentMarker.groovy in jenkinspipelines repo.


while getopts "a:" _opt; do

  case $_opt in

    a)
        appName=$OPTARG
         ;;
   \? | * | h )

      ;;
  esac
done
data=$(cat << EOF
{
  "deployment": {
    "revision": "$commitId",
    "changelog": "Added: /v2/deployments.rb, Removed: None",
    "description": "Added a deployments resource to the v2 API",
    "user": "datanerd@example.com"
  }
}
EOF
)
##-----
## main
##-----
adminAPIKey=$(echo "$ADMINAPIKEY")
echo $appName
echo $adminAPIKey
APP_ID=$(curl -X GET https://api.newrelic.com/v2/applications.json -H "X-Api-Key:$adminAPIKey" -G -d "filter[name]=$appName" | jq '. | .applications[0] .id')
echo $APP_ID
echo DATA we are passing is "$data"
curl -X POST "https://api.newrelic.com/v2/applications/${APP_ID}/deployments.json" -H "X-Api-Key:${adminAPIKey}" -i -H 'Content-Type: application/json' -d "${data}"
