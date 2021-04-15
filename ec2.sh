#!/bin/bash

### AWS CLI AUTOMATION
## Written by: Michael Jarnling
# School project to automate some AWS tasks

## EARLY NOTES
# bring in arguments like createkeys, 
#+ list, start, stop, run, terminate,
#+ allocate-elastic, assoc-elastic, disassoc-elastic, release-elastic
#+ create-vpc, create-subnet, create-route,
#+ create-igw, attach-igw, detach-igw, delete-igw

function createKeys () {
	# param: name
	echo "Creating keys..."
	# aws ec2 create-key-pair --key-name <name>
}

function listInstances () {
	# param: none
	echo "Listing instances..."
	# aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" --query "Reservations[].Instances[].InstanceId"
}

function runInstance () {
	# param: image id, type, key name, subnet id, sec group id
	echo "Creating instance..."
	# aws ec2 run-instances --image-id <image-id> --count <1-9> --instance-type <type> --key-name <keyname> --subnet-id <subnet-id> --security-group-ids <security-group-id>
	# ex:
	# aws ec2 run-instances --image-id ami-0742b4e673072066f --count 1 --instance-type t2.micro --key-name michaelschool --subnet-id subnet-9c0e78bd --security-group-ids sg-04e83d3d8a323078d
}

function startInstance () {
	# param: instance id
	echo "Starting instance..."
	# aws ec2 start-instances --instance-ids <instance-ids>
}

function stopInstance () {
	# param: instance id
	echo "Stopping instance..."
	# aws ec2 stop-instances --instance-ids <instance-ids>
}

function terminateInstance () {
	# param: instance id
	echo "Terminating instance..."
	# aws ec2 terminate-instances --instance-ids <instance-ids>
}

function allocateElastic () {
	# param: none
	echo "Allocating Elastic IP..."
	# aws ec2 allocate-address 
}

function associateElastic () {
	# param: allocation id, instance id
	echo "Associating Elastic IP with..."
	# aws ec2 associate-address --allocation-id <allocation-id> --instance-id <instance-id>
}

function disassociateElastic () {
	# param: association id
	echo "Disassociating Elastic IP from..."
	# aws ec2 disassociate-address --association-id <association-id>
}

function releaseElastic () {
	# param: allocation id
	echo "Releasing Elastic IP..."
	# aws ec2 release-address --allocation-id <allocation-id>
}

function createVPC () {
	# param: cidr block
	echo "Creating VPC..."
	# aws ec2 create-vpc --cidr-block <cidr block> --
	# ex:
	# aws ec2 create-vpc --cidr-block 10.0.0.0/16
}

function describeVPC () {
	# param: vpc id
	echo "Describing VPC..."
	# aws ec2 describe-vpcs --vpc-id <vpc-id>
}

function createSubnet () {
	# param: vpc id, cidr block, az name
	echo "Creating subnet..."
	# aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block <cidr-block> --availability-zone <az-name>
	# ex:
	# aws ec2 create-subnet --vpc-id aea3a43eajhja --cidr-block 10.0.1.0/24 --availability-zone us-east-1d
}

function createRoute () {
	echo "Creating route..."
}

function attachRoute () {
	echo "Attaching route..."
}

function createIGW () {
	# param: none
	echo "Creating Internet Gateway..."
	# aws ec2 create-internet-gateway
}

function attachIGW () {
	# param: igw id, vpc id
	echo "Attaching Internet Gateway..."
	# aws ec2 attach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>
}

function describeIGW () {
	# param: [vpc id, igw id]
	echo "Describing Internet Gateway..."
	# aws ec2 describe-internet-gateway [--filters <value>]
	# possibly usable filters: attachment.vpc-id (if attached to VPC), internet-gateway-id <igw-id>
}

function detachIGW () {
	# param: igw id, vpc id
	echo "Detaching Internet Gateway..."
	# aws ec2 detach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>
}

function deleteIGW () {
	# param: igw id
	echo "Deleting Internet Gateway..."
	# aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>
}

function showhelp () {
	echo "Listing help info..."
	printf "networking:\n\tcreate-vpc,\n\tcreate-igw,\n\tattach-igw,\n\tcreate-route,\n\tattach-route,\n\tcreate-subnet,\n\tallocate-elastic,\n\tassociate-elastic,\n\t(more to come)\n"
	printf "instances:\n\trun-instance,\n\tlist-instances,\n\tstart-intance,\n\tstop-instance,\n\tcreate-keys\n"
}

# Order of business:
# 1. 	Create VPC
# 2. 	Create IGW
# 3. 	Attach IGW
# 4. 	Create Route
# 5. 	Attach Route to IGW
# 6. 	Create Subnet
# 7. 	Allocate Elastic
# 8. 	Create Key Pair
# 9. 	Create Instance (with keypair, on subnet)
# 10. 	Associate Elastic with Instance
# 11. 	??? 

if [[ -n "$1" ]]; then
	case "$1" in
		"create-vpc")
			createVPC;;
		"create-igw")
			createIGW;;
		"attach-igw")
			attachIGW;;
		"create-route")
			createRoute;;
		"attach-route")
			attachRoute;;
		"create-subnet")
			createSubnet;;
		"allocate-elastic")
			allocateElastic;;
		"associate-elastic")
			associateElastic;;
		"create-keys")
			createKeys;;
		"run-instance")
			runInstance;;
		"list-instances")
			listInstances;;
		"start-instance")
			startInstance;;
		"stop-instance")
			stopInstance;;
		"help")
			showhelp;;
		*)
			echo "Invalid parameter, see --help for more information.";;
	esac
fi

#echo "$1"
