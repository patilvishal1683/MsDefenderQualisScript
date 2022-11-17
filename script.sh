#! /usr/bin/bash

# sudo su
# Get All Repo
sudo yum repolist all &>> temp/log.log 

# Enable CentOs Repo

sudo yum-config-manager --enable CentOS-7 - Base &>> temp/log.log 

# Install Microsoft Repo
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm &>> temp/log.log 

# Change Permission to edit Repo

sudo chmod 777 /etc/yum.repos.d/microsoft-prod.repo &>> temp/log.log 

sudo cat << EOF > /etc/yum.repos.d/microsoft-prod.repo.rpmnew
[microsoft-prod]
name=Microsoft Defender for Endpoint
baseurl=https://packages.microsoft.com/rhel/7/prod/
enabled=1
fastestmirror_enabled=0
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF &>> temp/log.log 

sudo yum install mdatp -y  &>> temp/log.log 

# Create Dir if not exists 
sudo mkdir -p /etc/opt/microsoft/mdatp/managed && sudo touch /etc/opt/microsoft/mdatp/managed/mdatp_managed.json &>> temp/log.log 

# Change Permission to edit config file
sudo chmod 777 /etc/opt/microsoft/mdatp/managed/mdatp_managed.json &>> temp/log.log 

# config_file = '/etc/opt/microsoft/mdatp/managed/mdatp_managed.json'

sudo cat << EOF > /etc/opt/microsoft/mdatp/managed/mdatp_managed.json
{
   "antivirusEngine":{
      "enableRealTimeProtection":true,
      "passiveMode":false,
      "exclusionsMergePolicy":"merge",
      "exclusions":[
         {
            "$type":"excludedPath",
            "isDirectory":false,
            "path":"/var/log/system.log"
         },
         {
            "$type":"excludedPath",
            "isDirectory":true,
            "path":"/home"
         },
         {
            "$type":"excludedFileExtension",
            "extension":"pdf"
         },
         {
            "$type":"excludedFileName",
            "name":"cat"
         }
      ],
      "allowedThreats":[
         "EICAR-Test-File (not a virus)"
      ],
      "disallowedThreatActions":[
         "allow",
         "restore"
      ],
      "threatTypeSettingsMergePolicy":"merge",
      "threatTypeSettings":[
         {
            "key":"potentially_unwanted_application",
            "value":"block"
         },
         {
            "key":"archive_bomb",
            "value":"audit"
         }
      ]
   },
   "cloudService":{
      "enabled":true,
      "diagnosticLevel":"optional",
      "automaticSampleSubmissionConsent":"safe",
      "automaticDefinitionUpdateEnabled":true
   }
}
EOF &>> temp/log.log 

sudo aws s3 cp s3://485443633092-us-east-1-testscriptfiles/MicrosoftDefenderATPOnboardingLinuxServer.py ./MicrosoftDefenderATPOnboardingLinuxServer.py &>> temp/log.log  

sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py &>> temp/log.log 

# Test Installation
sudo mdatp health --field org_id &>> temp/log.log 
sudo mdatp health --field healthy &>> temp/log.log 
sudo mdatp connectivity test &>> temp/log.log 

# Qualys Scanner Installation

# Test Connectivity between Iguazio Data Node and qualys scanner server

sudo curl -vvv https://qagpublic.qg3.apps.qualys.com &>> temp/log.log 
# Checking connection status
if grep -R "Connected to qagpublic.qg3.apps.qualys.com" file.txt 
then 
   # Download the rpm file from aws s3 bucket 
   sudo aws s3 cp s3://485443633092-us-east-1-testscriptfiles/QualysCloudAgent.rpm ./QualysCloudAgent.rpm

   sudo rpm -ivh QualysCloudAgent.rpm

   Activationid=5a367004-668e-4c07-add1-c1f7765f1d97

   Customerid=79126142-172c-6c9b-8219-3239f99fb195

   sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=$Activationid CustomerId=$Customerid
   sudo chmod 777 /var/log/qualys/qualys-cloud-agent.log
   sudo cat /var/log/qualys/qualys-cloud-agent.log
else
   echo "Something Went Wrong Unable to connect to curl request."
   kill $!
fi &>> temp/log.log 

wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip &>> temp/log.log 
unzip AmazonCloudWatchAgent.zip &>> temp/log.log 
sudo ./install.sh &>> temp/log.log 
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:/alarm/AWS-CWAgentConfig -s &>> temp/log.log 

