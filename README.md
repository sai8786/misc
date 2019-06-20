# Createlaunchtemplate
Background: When we create a cluster with KOPS, it will create launchconfig and ASG in AWS. However, this may be not sufficient if you are trying to get your cluster use spot instances. This script will help you automate the process of using spot for your environment. 
This will create a launch template from a launchconfig by using the values from Launch config and then later, it will update ASG with the instances type provided by the end user.
Usage: ./createlaunchtemplate.sh -l <launchconfigname> -a <instancetype1> -b <instnacetype2> -c <instancetype3> -d <instancetype4>. 
  
  Here, for the script you will have to provide the launchconfig you would like to use for grabbing the values from to create a launchtemplate. Also, you will need to provide the Instancetypes for the spot. 
  
