#! /usr/bin/bash
sudo yum update -y 

# Install Microsoft Repo
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm

# Change Permission to edit Repo

sudo chmod 777 /etc/yum.repos.d/microsoft-prod.repo
# file='/etc/yum.repos.d'
sudo cat << EOF > /etc/yum.repos.d/microsoft-prod.repo
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
wget https://test-script-16.s3.ap-south-1.amazonaws.com/MicrosoftDefenderATPOnboardingLinuxServer.py
python3 MicrosoftDefenderATPOnboardingLinuxServer.py



