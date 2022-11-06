#! /usr/bin/bash
# sudo yum update -y 

# Get All Repo
yum repolist all

# Enable CentOs Repo


sudo yum-config-manager --enable CentOS-7 - Base

# Install Microsoft Repo
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm

# Change Permission to edit Repo

sudo chmod 777 /etc/yum.repos.d/microsoft-prod.repo

sudo su

# file='/etc/yum.repos.d'
sudo cat << EOF > /etc/yum.repos.d/microsoft-prod.repo.rpmnew
[microsoft-prod]
name=Microsoft Defender for Endpoint
baseurl=https://packages.microsoft.com/rhel/7/prod/
enabled=1
fastestmirror_enabled=0
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

yum install mdatp -y 

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
aws s3 cp s3://qualysanddefendersh/MicrosoftDefenderATPOnboardingLinuxServer.py ./MicrosoftDefenderATPOnboardingLinuxServer.py 2> response.txt
if grep -R "HTTP request sent, awaiting response... 200 OK" response.txt
then
   python3 MicrosoftDefenderATPOnboardingLinuxServer.py
else
   echo "Something Went Wrong Unable to Download Python file."
   kill $!
fi

# Qualys Scanner Installation

# Test Connectivity between Iguazio Data Node and qualys scanner server

curl -vvv https://qagpublic.qg3.apps.qualys.com 2> file.txt
# Checking connection status
if grep -R "Connected to qagpublic.qg3.apps.qualys.com" file.txt
then 
   # Download the rpm file from aws s3 bucket 
   aws s3 cp s3://qualysanddefendersh/QualysCloudAgent.rpm ./QualysCloudAgent.rpm

   rpm -ivh QualysCloudAgent.rpm

   Activationid=5a367004-668e-4c07-add1-c1f7765f1d97

   Customerid=79126142-172c-6c9b-8219-3239f99fb195

   sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=$Activationid CustomerId=$Customerid
   # kill $!
   # To acceess logs change user to superuser
   sudo su
   # sudo chmod 777 /var/log/qualys/qualys-cloud-agent.log
   cat /var/log/qualys/qualys-cloud-agent.log
else
   echo "Something Went Wrong Unable to connect to curl request."
   kill $!
fi
