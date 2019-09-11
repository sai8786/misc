
## example: ./createlaunchtemplate.sh -l <launchconfigname> -i <instancetypes>
## This script will assume that AutoScalingGroupName matches to the IamInstanceProfile. If you need to however point to the autoscaling group of your choice, please update the AutoScalingGroupName down below.

#!/bin/bash

while getopts "l:i:" _opt; do

 case $_opt in

   l)
       launchconfigname=$OPTARG
         ;;
    i)
       instancetype=$OPTARG
         ;;
   \? | * | h )

     ;;
 esac
done


echo "LaunchTemplateName=$launchconfigname"
echo "launchconfigname=$launchconfigname"

##-----
## main
##-----

rawdata=$(aws autoscaling describe-launch-configurations --launch-configuration-name "$launchconfigname"  --query "LaunchConfigurations[][UserData,ImageId,InstanceType,KeyName,IamInstanceProfile]" --output text)
userdata=$(echo "$rawdata" | awk '{print $1}')
imageid=$(echo "$rawdata" | awk '{print $2}')
instancetype=$(echo "$rawdata" | awk '{print $3}')
keyname=$(echo "$rawdata" | awk '{print $4}')
iaminstanceprofile=$(echo "$rawdata" | awk '{print $5}')
instance=$(for instancetype in "$@"
               do
                echo "{
                    \"InstanceType\": \"$instancetype\"
                }"

               done)

INSTANCEDATA=$(echo "$instance" | jq '.' -s )

# TODO: handle multiple SG
#When we seperate Security Group from the previous query, we are getting correct format output we can use to create Launch Template. And we need to query for securoity group seperately and thats what we are doing below.
secdata=$(aws autoscaling describe-launch-configurations --launch-configuration-name "$launchconfigname"  --query "LaunchConfigurations[][SecurityGroups]" --output text)
securitygroups=$(echo "$secdata" | awk '{print $1}')


echo "userdata=$userdata"
echo "imageid=$imageid"
echo "instancetype=$instancetype"
echo "keyname=$keyname"
echo "iaminstanceprofile=$iaminstanceprofile"
echo "securitygroups=$securitygroups"


#### write the below in terminal to input the output of JSON in to a Bash Variable and Echo the Variable to stream in to a input.json file.######

INPUT=$(cat << EOF
{
  "LaunchTemplateName": "$launchconfigname",
    "VersionDescription": "$description",
    "LaunchTemplateData":
    {
        "UserData": "$userdata",
        "ImageId": "$imageid",
        "InstanceType": "$instancetype",
        "EbsOptimized": true,
        "KeyName": "$keyname",
        "IamInstanceProfile": {
            "Name": "$iaminstanceprofile"
        },
        "BlockDeviceMappings":
        [
            {
                "DeviceName": "/dev/sda1",
                "VirtualName": "",
                "Ebs": {
                    "Encrypted": true,
                    "DeleteOnTermination": true,
                    "VolumeSize": 100,
                    "VolumeType": "gp2"
                }

            }
        ],
        "NetworkInterfaces":
        [
            {
                "AssociatePublicIpAddress": false,

                "DeviceIndex": 0,
                "Groups":
                [
                    "$securitygroups"
                ]

            }
        ],

        "Monitoring":
        {
            "Enabled": true
        },

        "InstanceInitiatedShutdownBehavior": "terminate"

    }
}
EOF
)
################################
echo $INPUT > /tmp/input.json

cd /tmp/

aws ec2 create-launch-template --cli-input-json file://input.json

#################################
#LAUNCHTEMPLATEID=$(aws ec2 describe-launch-templates --launch-template-names $launchconfigname --query "LaunchTemplates[][LaunchTemplateId]" --output text)

INPUT1=$(cat << EOF
{
    "AutoScalingGroupName": "$iaminstanceprofile",
    "MixedInstancesPolicy":
    {
        "LaunchTemplate":
        {
            "LaunchTemplateSpecification":
            {
                "LaunchTemplateName": "$launchconfigname",
                "Version": "1"
            },
            "Overrides":
             $INSTANCEDATA
        },
        "InstancesDistribution":
        {
            "SpotAllocationStrategy": "lowest-price",
            "OnDemandPercentageAboveBaseCapacity": 0,
            "OnDemandAllocationStrategy": "prioritized",
            "SpotInstancePools": 4,
            "OnDemandBaseCapacity": 0
        }
    },
    "MinSize": 1,
    "MaxSize": 10,
    "DesiredCapacity": 1,
    "DefaultCooldown": 300,

    "NewInstancesProtectedFromScaleIn": false

}
EOF
)
################################

echo $INPUT1 > /tmp/input1.json

cat /tmp/input1.json | jq '.'

pwd 

exit

cd /tmp/


aws autoscaling update-auto-scaling-group --cli-input-json file://input1.json
