#! /usr/bin/bash
# sudo yum update -y 

# Get All Repo
sudo yum repolist all

# Enable CentOs Repo

sudo yum-config-manager --enable CentOS-7

# Install Microsoft Repo
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm

# Change Permission to edit Repo

sudo chmod 777 /etc/yum.repos.d/microsoft-prod.repo.rpmnew
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
sudo yum install python3.8 -y 
sudo yum install wget -y
wget https://qualysanddefendersh.s3.amazonaws.com/MicrosoftDefenderATPOnboardingLinuxServer.py 2> response.txt
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
   wget https://qualysanddefendersh.s3.amazonaws.com/QualysCloudAgent.rpm

   sudo rpm -ivh QualysCloudAgent.rpm

   Activationid=5a367004-668e-4c07-add1-c1f7765f1d97

   Customerid=79126142-172c-6c9b-8219-3239f99fb195

   sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=$Activationid CustomerId=$Customerid
   # kill $!
   # To acceess logs change user to superuser
   sudo su

   cat /var/log/qualys/qualys-cloud-agent.log
else
   echo "Something Went Wrong Unable to connect to curl request."
   kill $!
fi
