#!/bin/bash
mkdir -p /tmp/aws-export/iam /tmp/aws-export/account-authorization-details /tmp/aws-export/dns

for profile in $(grep '^[[]profile' <~/.aws/config | awk '{print $2}' | sed 's/]$//'); do 
	echo -e " --- Export IAM Users from: "$profile" account --- ";  
	aws --profile $profile iam list-users |jq -r . >> /tmp/aws-export/iam/list-users-$profile.txt; 

	echo "Export IAM Roles from: "$profile" account --- ";  
	aws --profile $profile iam list-roles |jq -r . >> /tmp/aws-export/iam/list-roles-$profile.txt; 

	echo -e " --- Export IAM Policies from: "$profile" account --- ";  
	aws --profile $profile iam list-policies |jq -r . >> /tmp/aws-export/iam/list-policies-$profile.txt; 

	echo "Export IAM Account Autorization from: "$profile" account --- ";  
	aws --profile $profile iam get-account-authorization-details|jq -r . >> /tmp/aws-export/account-authorization-details/account-authorization-$profile.txt; 

	echo "Export Route53 hosted-zones from: "$profile" account --- ";  
	aws --profile $profile route53 list-hosted-zones|jq '.[] | .[] | .Id' | sed 's!/hostedzone/!!' | sed 's/"//g' >> /tmp/aws-export/dns/hosted-zones-$profile.txt;
	for zone in `cat /tmp/aws-export/dns/hosted-zones-$profile.txt`; do 
		echo "Export Route53 resource-record-sets "$zone" from: "$profile" account --- ";
		aws --profile $profile route53 list-resource-record-sets --hosted-zone-id $zone >> /tmp/aws-export/dns/resource-record-sets-$profile.txt;
		echo -e "\n#-------\n" >> /tmp/aws-export/dns/resource-record-sets-$profile.txt;
	done;
done

aws iam list-users |jq -r . >> /tmp/aws-export/iam/list-users-ROOT-account.txt; 
aws iam list-roles |jq -r . >> /tmp/aws-export/iam/list-roles-ROOT-account.txt; 
aws iam list-policies |jq -r . >> /tmp/aws-export/iam/list-policies-ROOT-account.txt; 
aws iam get-account-authorization-details|jq -r . >> /tmp/aws-export/account-authorization-details/account-authorization-ROOT-account.txt; 


"""
Ref: 
https://aws.amazon.com/blogs/security/a-simple-way-to-export-your-iam-settings/
https://docs.aws.amazon.com/cli/latest/reference/iam/list-users.html
https://docs.aws.amazon.com/workdocs/latest/adminguide/download-user.html
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html
"""
