#!/bin/bash
#----------------------------------------------------------------------------------------
# v0.1.0-beta
# This script generate a simple but useful info about some data in your aws accounts
#----------------------------------------------------------------------------------------

#--------- GENERAL VARS ----------------------------------
outputfile="workermouse.html"
slackchannel="1234567890"
slacktoken="xoxp-aaaaaaaaaa-bbbbbbbbbbb-ccccccccc-dddddddddddddddddddd"
delete_instances="true" # Pending implement. 
aws_region="us-east-1"

#---------------------------------------------------------
# My custom functions with common aws cli commands 
#---------------------------------------------------------
function spy_mouse {
  	echo "<hr>Profile: $profile | spy-mouse:  Instances that do not have the Name, Environment and/or ShutingOff tags <hr>"
	aws --profile $profile ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(contains({Tags: [{Key: "Name"},{Key: "Environment"},{Key: "ShutingOff"} ]}) | not).InstanceId' || echo "No resources found"
}

function spy_mouse_ebs {
	echo "<hr>Profile: $profile | spy-mouse:  Unused or unassigned Volumes (EBS) <hr>"
	aws --profile $profile ec2 describe-volumes --filter "Name=status,Values=available" --query 'Volumes[*].{VolumeID:VolumeId,Size:Size,Type:VolumeType,AvailabilityZone:AvailabilityZone,CreateTime:CreateTime}' --output text || echo "No resources found"
}

function maintenance_mouse {
	echo "<hr>Profile: $profile | maintenance-mouse: Instances that have shutingoff = true <hr>"
	aws --profile $profile ec2 describe-instances --filter Name=tag:ShutingOff,Values=True --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value|[0]]' --output text || echo "No resources found"
	#
	echo "<hr>Profile: $profile | murder-mouse: Instances that have TerminateDate tag <hr>"
	aws --profile $profile ec2 describe-instances  --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`].Value|[0],Tags[?Key==`TerminateDate`].Value|[0]]' --output text|grep -v "None" || echo "No resources found"
}

function maintenance_mouse_security {
	echo "<hr>Profile: $profile | maintenance-mouse: Security Grouos with 0.0.0.0/0 <hr>"
	aws --profile $profile ec2 describe-security-groups --filter Name=ip-permission.protocol,Values=-1 Name=ip-permission.cidr,Values='0.0.0.0/0' --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" --output table
}

function finger_mouse {
	echo "<hr>Profile: $profile | finger-mouse: search for Unallocated elastic IPs <hr>"
	aws --profile $profile ec2 describe-addresses --region $aws_region --output json | jq -r '.Addresses | .[] | select(.AssociationId == null)'|jq -r .PublicIp 
}


# Create a simple html file with data and explication. (send to stdout and to file)
echo "<html><div align='center'><h1>Worker-Mouse scanning v0.1.0-beta</h1>
<img src='https://cdn2.vectorstock.com/i/1000x1000/37/76/cute-mouse-worker-cartoon-vector-17553776.jpg' width='70' height='100'><br>
<hr>
<h3><i>Worker mouse</i>: It looks for resources with certain labels, and based on it takes concrete actions. <br>
Designed to our developers avoid having orphaned resources and spend money on unused hardware.<br>
<div align='left'>
 <ul>
  <li>Spy-mouse: look for instances that do not have the name, environment, poweroff tags</li>
  <li>Maintenance-mouse: Look for instances that have poweroff=true to stop it at the night (using resources only in working hours)</li>
  <li>Murder-mouse: Look for instances that have a Termination Date > 10 days and then he kills them (Terminate instances)</li>
</ul> 
<br><pre><br>"  | tee $outputfile


#---------------------------------------------------------
# This bucle, use your profile to obtain all aws accounts and get data from all.
# remember you need to have .aws/config and ./aws/credentials
#---------------------------------------------------------
for profile in $(grep '^[[]profile' <~/.aws/config | awk '{print $2}' | sed 's/]$//'); do
	spy_mouse
	spy_mouse_ebs
	maintenance_mouse
	maintenance_mouse_security
	finger_mouse
	# Add here your own custom functions
done | tee $outputfile

# Create a tota size volumes
total_size=$(cat $outputfile|grep vol- |awk {'print  $3'}|tr '\n' '+ ' | sed 's/.$//';); echo "<br><br><hr>Total Size $(($total_size))Gb on orphans volumes (between all aws accounts)  </pre></html>" >> $outputfile

# Create a PDF
wkhtmltopdf $outputfile workermouse.pdf

# Send data to slack channel
curl -sF "initial_comment=:the_horns: Mouse Report :mouse2:" -F file=@workermouse.pdf -F channels=$slackchannel -F token=$slacktoken  https://slack.com/api/files.upload |jq -r .ok
