#!/bin/bash
###################################################################################
#UNCLASSIFIED
#
Function="Reads the ~.aws/credentials file, displays a list and executes profile"
#
#Contraints: 
#
Arguments="Standard options are function, arguments, usage, developer, version, help"
Usage="unset: unset the AWS_PROFILE environment variable"
#
Developer=212319741
#R1	Still in development
Version=R1
###################################################################################
#Global Variables
Profiles=""
Credential_file=~/.aws/credentials
Unset=""
Token_File=~/.aws/token
MFA_ARN_File=~/.aws/mfa.cfg
 
#-------------------------------------SUBROUTINES----------------------------------
#Usage message
#Usage message
usage()
{	
	local Display=$1
	[ $Display == "function" ] && echo "Function is $Function"
	[ $Display == "arguments" ] && echo "Arguments: $Arguments"
	[ $Display == "usage" ] && echo "Usage $Usage"
	[ $Display == "help" ] && echo -e "Function: $Function\nArguments: $Arguments\nUsage: $Usage\nDeveloper: $D
eveloper\nVersion: $Version"
	[ $Display == "developer" ] && echo "Developer $Developer"	
	[ $Display == "version" ] && echo "Version $Version"
	exit 13
}

#-------------------------------------MAIN SECTION----------------------------------
#Display help 
for Arg in "$@"
	do
	[ $Arg == "function" ] && usage function
	[ $Arg == "arguments" ] && usage arguments
	[ $Arg == "usage" ] && usage usage	
	[ $Arg == "help" ] && usage help
	[ $Arg == "developer" ] && usage developer
	[ $Arg == "version" ] && usage version
	done

AWS_CLI=`which aws`
if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed or not set in /$PATH; exiting"
  exit 1
fi

select choice in $(egrep "^\[" $Credential_file)
	do 
		if [[ "$choice" ]]
			then 
#				Profile=$choice
				Profile=${choice:1:${#choice}-2}
				break
			else 
				echo "invalid choice!"
		fi
	done

MFA_ARN=`awk -F'"' "/^$Profile/"'{print $2 }' $MFA_ARN_File`
if [ $? -ne 0 ]; then
  echo "ARN is missing from ~/mfa.cfg for selected AWS Profile"
  exit 1
fi
	
read -p "Please enter MFA Token:  " MFA_Token
while [[ -z "$MFA_Token" ]]
	do
		echo "MFA Token required"
		echo ""
		read -p "Please enter MFA Token:  " MFA_Token
		echo ""
	done


#echo "AWS-CLI Profile: /"$Profile/""
#echo "MFA ARN: /"$MFA_ARN/""
#echo "MFA Token Code: /"$MFA_Token/""

aws --profile $Profile sts get-session-token --duration 129600 \
  --serial-number $MFA_ARN --token-code $MFA_Token --output text \
  | awk '{printf("export AWS_ACCESS_KEY_ID=\"%s\"\nexport AWS_SECRET_ACCESS_KEY=\"%s\"\nexport AWS_SESSION_TOKEN=\"%s\"\nexport AWS_SECURITY_TOKEN=\"%s\"\n",$2,$4,$5,$5)}' > $Token_File

echo "Setting AWS_PROFILE to $Profile with STS Token"
source $Token_File
PS1="[$Profile \W]\\$ "

