# Deloitte

Response to Deloitte Technical Exercise.

## To run the container

```
docker run -d -p 5000:5000 peterwatt/flaskdemo

curl http://127.0.0.1:5000
```

## Container design

Since Docker Hub doesn’t have an official Flask image, I built my own. While you can always use a non-official image, it’s generally recommended to make your own Dockerfile to ensure you know what is in the image. 

I am using the Docker Official image [python:alpine](https://hub.docker.com/_/python).

This image is based on the popular Alpine Linux project, available in the alpine official image. Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general. This base image is safe because it is the official image mantained by the Docker community.

The Python code has been changed to bind to 0.0.0.0 (see [here](https://stackoverflow.com/questions/30323224/deploying-a-minimal-flask-app-in-docker-server-connection-issues)).

## AWS execution platform

*AWS Fargate* has been selected as the Kubernetes container platform (see [here](https://aws.amazon.com/blogs/aws/amazon-eks-on-aws-fargate-now-generally-available/)).

Fargate is a managed compute engine for Amazon ECS that can run containers. In Fargate you don’t need to manage servers or clusters.

Fargate allocates the right amount of compute, eliminating the need to choose instances and scale cluster capacity. You only pay for the resources required to run your containers, so there is no over-provisioning and paying for additional servers. Fargate runs each task or pod in its own kernel providing the tasks and pods their own isolated compute environment. This enables your application to have workload isolation and improved security by design.

It is a good practice to consume the AWS managed service, if commercially viable, because this means that the responsibility for implementing best practice (the Well Architected Framework) lies with AWS rather than the customer.

### Characteristcs of the platform

The value proposition for AWS Fargate:

* Serverless platform (described here: https://pages.awscloud.com/fargate-serverless-architecture.html)

* Implements three Flask application pods across three availability zones for fault tolerance

### Building the platform

A [Makefile](Makefile) is provided.

Issue the following commands:

```
aws configure set default.region us-east-2

make build
```

### Sample output
```
[ℹ]  eksctl version 0.13.0
[ℹ]  using region us-east-2
[ℹ]  setting availability zones to [us-east-2a us-east-2b us-east-2c]
[ℹ]  subnets for us-east-2a - public:192.168.0.0/19 private:192.168.96.0/19
[ℹ]  subnets for us-east-2b - public:192.168.32.0/19 private:192.168.128.0/19
[ℹ]  subnets for us-east-2c - public:192.168.64.0/19 private:192.168.160.0/19
[ℹ]  using Kubernetes version 1.14
[ℹ]  creating EKS cluster "demo-flask" in "us-east-2" region with Fargate profile
[ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-2 --cluster=demo-flask'
[ℹ]  CloudWatch logging will not be enabled for cluster "demo-flask" in "us-east-2"
[ℹ]  you can enable it with 'eksctl utils update-cluster-logging --region=us-east-2 --cluster=demo-flask'
[ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "demo-flask" in "us-east-2"
[ℹ]  1 task: { create cluster control plane "demo-flask" }
[ℹ]  building cluster stack "eksctl-demo-flask-cluster"
[ℹ]  deploying stack "eksctl-demo-flask-cluster"
[✔]  all EKS cluster resources for "demo-flask" have been created
[✔]  saved kubeconfig as "/Users/peterwatt/.kube/config"
[ℹ]  creating Fargate profile "fp-default" on EKS cluster "demo-flask"
[ℹ]  created Fargate profile "fp-default" on EKS cluster "demo-flask"
[ℹ]  "coredns" is now schedulable onto Fargate
[ℹ]  "coredns" is now scheduled onto Fargate
[ℹ]  "coredns" pods are now scheduled onto Fargate
[ℹ]  kubectl command should work with "/Users/s66234/.kube/config", try 'kubectl get nodes'
[✔]  EKS cluster "demo-flask" in "us-east-2" region is ready

```

### Exposing the service

Amazon EKS doesn't support the Network Load Balancer and Classic Load Balancer for pods running on AWS Fargate. For Fargate ingress, it's a best practice to use the [ALB Ingress Controller](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) on Amazon EKS.

Futher details [here](https://aws.amazon.com/blogs/containers/using-alb-ingress-controller-with-amazon-eks-on-fargate/).

The Makefile implements the ALB Ingress Controller, but there is one manual step to be performed. Open the ALB Ingress Controller deployment manifest for editing with the following command.

```
kubectl edit deployment.apps/alb-ingress-controller -n kube-system
```

Add a line for the cluster name, the VPC ID, and AWS Region name after the `--ingress-class=alb` line. Once you've added the appropriate lines, save and close the file.

```
    spec:
      containers:
      - args:
        - --ingress-class=alb
        - --cluster-name=demo-flask
        - --aws-vpc-id=vpc-1111111111111111
        - --aws-region=us-east-2
```

## Kuberbetes deployment resources

The service is described in YAML in [flask.yaml](flask.yaml).

The command to build the service is:

```
kubectl apply -f flask.yaml
```

### To test the service

Get the DNS name of the load balancer:

```
kubectl get ingress
```
The load balancer will respond on port 80.

### Cleaning up the platform

Issue the following command:

```
make cleanup
```
