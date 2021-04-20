#!/bin/bash

## General
# . Create SSH keys
## Networking
# . Create VPC
# . Create two subnets
# . Create IGW
# . Attach IGW to VPC
# . Create public route table for VPC
# . Associate route with public subnet
## Instances
# . Create a specific security group for ssh and http (public server)
# . Create a separate security group for internal traffic (private server)
# . Get Ubuntu Image
# . Run IT instance with public security group above
# . Run Finance instance with private security group
## Elastic IP
# . Allocate Elastic IP
# . Associate Elastic IP with IT instance

function createKeys () {
	# param: name
	keyname="$1"
	echo "Creating keys..."
	aws ec2 create-key-pair --key-name "$keyname"
	# aws ec2 create-key-pair --key-name <name>
}

function createVPC () {
	# param: cidr block
	echo "Creating VPC..."
	local raw=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text)
	cvpc=$(echo "$raw" | grep "pending" | awk '{print $8}')
	echo "- VPC ID: $cvpc"
	# aws ec2 create-vpc --cidr-block <cidr block> --
	# ex:
	# aws ec2 create-vpc --cidr-block 10.0.0.0/16
}

function createSubnets () {
	# param: vpc id, cidr block, az name
	local vpcid="$1"
	local pubcidr="10.0.1.0/24"
	local privcidr="10.0.2.0/24"
	local az="us-east-1d"
	echo "Creating subnets..."
	local subraw=$(aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block "$pubcidr" --availability-zone "$az" --output text)
	pubsub=$(echo "$subraw" | awk '{print $12}')
	echo "- Public Subnet ID: $pubsub"
	local subraw=$(aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block "$privcidr" --availability-zone "$az" --output text)
	privsub=$(echo "$subraw" | awk '{print $12}')
	echo "- Private Subnet ID: $privsub"
	# aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block <cidr-block> --availability-zone <az-name>
	# ex:
	# aws ec2 create-subnet --vpc-id aea3a43eajhja --cidr-block 10.0.1.0/24 --availability-zone us-east-1d
}

function createIGW () {
	# param: none
	echo "Creating Internet Gateway..."
	local raw=$(aws ec2 create-internet-gateway --output text)
	igw=$(echo "$raw" | awk '{print $2}')
	echo "- Internet Gateway: $igw"
	# aws ec2 create-internet-gateway
}

function attachIGW () {
	# param: igw id, vpc id
	local vpcid="$1"
	local igwid="$2"
	echo "Attaching Internet Gateway..."
	local raw=$(aws ec2 attach-internet-gateway --vpc-id "$vpcid" --internet-gateway-id "$igwid" --output text)
	echo "- $igwid attached to $vpcid"
	# there is no output from this command on success
	# aws ec2 attach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>
}

function createRouteTable () {
	# param: vpc id
	local vpcid="$1"
	echo "Creating route table..."
	local raw=$(aws ec2 create-route-table --vpc-id="$vpcid" --output text)
	routetable=$(echo $raw | awk '{print $3}')
	echo "- Route Table ID: $routetable"
	# aws ec2 create-route-table --vpc-id <vpc-id>
}

function createRoute () {
	# param: vpc id, igw id, route table id
	local rtid="$1"
	local igwid="$2"
	local vpcid="$3"
	echo "Creating route..."
	local raw=$(aws ec2 create-route --route-table-id "$rtid" --gateway-id "$igwid" --destination-cidr-block "0.0.0.0/0")
	echo "- Route created between Route Table $rtid and Internet Gateway $igwid" 
	# aws ec2 create-route --route-table-id <route table id> --gateway-id <igw-id> --destination-cidr-block <0.0.0.0/0>
}

function associateRoute () {
	# params: route table id, [subnet id, igw id]
	local rtid="$1"
	local subid="$2"
	echo "Associating route with subnet..."
	local raw=$(aws ec2 associate-route-table --route-table-id "$rtid" --subnet-id "$subid" --output text)
	assocrouteid=$(echo $raw | awk '{print $2}')
	echo "- Route Table $rtid associated with Subnet $subid"
	# aws ec2 associate-route-table --route-table-id <route-table-id> [--subnet-id <subnet-id>] [--gateway-id <igw-id>]
}

function getImage () {
	echo "Fetching image id..."
	imageid=$(aws ec2 describe-images --owner 099720109477 --query 'Images[*].[ImageId]' --output text --filters "Name=architecture,Values=x86_64" "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210223")
	echo "- Image ID for Ubuntu 20.04: $imageid"
	# aws ec2 describe-images --owner 099720109477 --query 'Images[*].[ImageId]' --output text --filters "Name=architecture,Values=x86_64" "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210223"
	# returns: ami-042e8287309f5df03
}

function createSG () {
	echo "Creating security groups..:"
	# public
	local raw=$(aws ec2 create-security-group --group-name "Public SG" --description "SG for the public instances" --output text)
	pubsg=$(echo $raw | awk '{print $1}')
	echo "- Public Security Group: $pubsg"
	# private
	local raw=$(aws ec2 create-security-group --group-name "Private SG" --description "SG for the private instances" --output text)
	privsg=$(echo $raw | awk '{print $1}')
	echo "- Private Security Group: $privsg"
}

function createRules () {
	echo "Modifying security group rules..."
	# public allow ingress port 80
	aws ec2 authorize-security-group-ingress --group-id "$pubsg" --protocol tcp --port 80 --cidr "0.0.0.0/0"
}

function runInstance () {
	# param: image id, type, key name, subnet id, sec group id
	echo "Creating instance..."
	# public
	local raw=$(aws ec2 run-instances --image-id "$imageid" --count 1 --instance-type "t2.micro" --key-name "$keyname" --subnet-id "$pubsub" --security-group-ids "$pubsg" --output text --query "Instances[].InstanceId")
	pubinstance=$(echo "$raw")
	# private
	local raw=$(aws ec2 run-instances --image-id "$imageid" --count 1 --instance-type "t2.micro" --key-name "$keyname" --subnet-id "$privsub" --security-group-ids "$privsg" --output text --query "Instances[].InstanceId")
	privinstance=$(echo "$raw")
	# aws ec2 run-instances --image-id <image-id> --count <1-9> --instance-type <type> --key-name <keyname> --subnet-id <subnet-id> --security-group-ids <security-group-id>
	# ex:
	# aws ec2 run-instances --image-id ami-0742b4e673072066f --count 1 --instance-type t2.micro --key-name michaelschool --subnet-id subnet-9c0e78bd --security-group-ids sg-04e83d3d8a323078d
	# ubuntu 20 LTS x64 - ami-042e8287309f5df03
}

function allocateElastic () {
	# param: none
	echo "Allocating Elastic IP..."
	local raw=$(aws ec2 allocate-address --domain vpc --network-border-group us-east-1 --output text)
	allocationid=$(echo "$raw" | awk '{print $1}')
	elasticip=$(echo "$raw" | awk '{print $4}')
	echo "- Elastic IP: $elasticip allocated with id: $allocationid"
	# aws ec2 allocate-address --domain vpc --network-border-group us-east-1 --output text
	# ex output: eipalloc-0d47df0404e8cc30d      vpc     us-east-1       54.237.44.241   amazon
}

function associateElastic () {
	# param: allocation id, instance id
	echo "Associating Elastic IP with public instance..."
	local raw=$(aws ec2 associate-address --alocation-id "$allocationid" --instance-id "$pubinstance")
	echo "Instance: $pubinstance associated with Elastic IP $elasticip"
	# aws ec2 associate-address --allocation-id <allocation-id> --instance-id <instance-id>
}

### EXECUTE

## Create VPC
createVPC

## Create Subnets
createSubnets "$cvpc"

## Create IGW
createIGW
# Attach IGW
attachIGW "$cvpc" "$igw"

## Routing
# Create route table
createRouteTable "$cvpc"
# Create route
createRoute "$routetable" "$igw"
# Associate route with public subnet
associateRoute "$routetable" "$pubsub"

## Instances
# Keys
createKeys "cr8Uf5uEmL"

# Get Ubuntu Image
getImage

# Create security groups and apply rules
createSG
createRules

# Run instances
runInstance

## Elastic IP
# Allocate Elastic IP
allocateElastic

# Associate Elastic IP
associateElastic

### DONE

