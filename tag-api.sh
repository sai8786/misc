#!/bin/bash
# Script to tag APIGateway Stages using AWSCLI
# process switch arguments
# if syntax passes, parameter values will be contained in
# Example: ./tag.sh -t -r <regionname> -y -s <stageName> devint -su inventory -e devint -i <RestapiID>

die() {
  echo -e "$*" 1>&2
  exit 1
}


#while getopts ":y" _opt; do
aws_region=""
stagename=""
subsystem=""
env1=""

# while getopts ":y:r:s:x:e:" _opt; do
while getopts "r:s:x:e:t:c:" _opt; do

  case $_opt in

    r)
      aws_region=$OPTARG
        ;;
    s)
       stagename=$OPTARG
        ;;
    x)
         subsystem=$OPTARG
           ;;
     e)
          env=$OPTARG
            ;;
     t)
          tier=$OPTARG
          ;;
     c)
          client=$OPTARG
                 ;;

    \? | * | h )

      ;;
  esac
done


tags="BUSINESS_REGION=NORTHAMERICA,BUSINESS_UNIT=RETAIL,PLATFORM=SB-SBX,CLIENT=${client},ENV=${env},TIER=${tier},SUBSYSTEM=${subsystem}"

echo "sbx-$aws_region-$env-$subsystem-apigw"

restapiid=$(aws apigateway get-rest-apis --query "items[?name=='sbx-$aws_region-$env-$subsystem-apigw'][id]" --output text)


echo "restapi-id is $restapiid"


aws apigateway tag-resource --resource-arn "arn:aws:apigateway:${aws_region}::/restapis/${restapiid}/stages/${stagename}" --tags="${tags}"
