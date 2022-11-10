#! /usr/bin/bash

# sudo su
# Get All Repo
sudo yum repolist all

# Enable CentOs Repo

sudo yum-config-manager --enable CentOS-7 - Base

# Install Microsoft Repo
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm

# Change Permission to edit Repo

sudo chmod 777 /etc/yum.repos.d/microsoft-prod.repo

sudo cat << EOF > /etc/yum.repos.d/microsoft-prod.repo.rpmnew
[microsoft-prod]
name=Microsoft Defender for Endpoint
baseurl=https://packages.microsoft.com/rhel/7/prod/
enabled=1
fastestmirror_enabled=0
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sudo yum install mdatp -y 

# Create Dir if not exists 
sudo mkdir -p /etc/opt/microsoft/mdatp/managed && sudo touch /etc/opt/microsoft/mdatp/managed/mdatp_managed.json

# Change Permission to edit config file
sudo chmod 777 /etc/opt/microsoft/mdatp/managed/mdatp_managed.json

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
EOF
sudo aws s3 cp s3://qualysanddefendersh/MicrosoftDefenderATPOnboardingLinuxServer.py ./MicrosoftDefenderATPOnboardingLinuxServer.py 

sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py

# Test Installation
sudo mdatp health --field org_id 
sudo mdatp health --field healthy
sudo mdatp connectivity test

# Qualys Scanner Installation

# Test Connectivity between Iguazio Data Node and qualys scanner server

sudo curl -vvv https://qagpublic.qg3.apps.qualys.com 2> file.txt
# Checking connection status
if grep -R "Connected to qagpublic.qg3.apps.qualys.com" file.txt
then 
   # Download the rpm file from aws s3 bucket 
   sudo aws s3 cp s3://qualysanddefendersh/QualysCloudAgent.rpm ./QualysCloudAgent.rpm

   sudo rpm -ivh QualysCloudAgent.rpm

   Activationid=5a367004-668e-4c07-add1-c1f7765f1d97

   Customerid=79126142-172c-6c9b-8219-3239f99fb195

   sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=$Activationid CustomerId=$Customerid
   sudo chmod 777 /var/log/qualys/qualys-cloud-agent.log
   sudo cat /var/log/qualys/qualys-cloud-agent.log
else
   echo "Something Went Wrong Unable to connect to curl request."
   kill $!
fi

wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
unzip AmazonCloudWatchAgent.zip
sudo ./install.sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:/alarm/AWS-CWAgentConfig -s
aws s3 cp s3://qualysanddefendersh/script.sh ./script.sh 2> response.txt
