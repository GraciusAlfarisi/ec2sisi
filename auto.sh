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
# . Create a specific security group for ssh and http (use default for the internal server)
# . Get Ubuntu Image
# . Run IT instance with new security group above
# . Run Finance instance with default security group
## Elastic IP
# . Allocate Elastic IP
# . Associate Elastic IP with IT instance

function createKeys () {
	# param: name
	echo "Creating keys..."
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

# Get Ubuntu Image

# Create security group

# Run public instance

# Run private instance

## Elastic IP
# Allocate Elastic IP

# Associate Elastic IP


### DONE


