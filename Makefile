### Import environment variables
#include $(config)

define HELP_TEXT
Usage: make [TARGET]...
!!IMPORTANT!! before running make [TARGET], please make sure you are running suitable role in correct AWS account...
Available targets:
endef
export HELP_TEXT

help: ## This help
	@echo "$$HELP_TEXT"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "\033[36m%-30s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

cleanup: ## Tear down all components

	aws cloudformation delete-stack --stack-name eksctl-demo-flask-addon-iamserviceaccount-kube-system-alb-ingress-controller
	
	eksctl delete cluster --name demo-flask --region us-east-2

	aws cloudformation delete-stack --stack-name eksctl-demo-flask-cluster

	aws iam delete-policy --policy-arn arn:aws:iam::$$(aws sts get-caller-identity --query Account --output text):policy/ALBIngressControllerIAMPolicy

build: ## Build platform

#	Create an EKS cluster with Fargate support

	eksctl create cluster --name demo-flask --region us-east-2 --fargate

	eksctl utils update-cluster-logging --region=us-east-2 --cluster=demo-flask --enable-types all --approve

#	Create an IAM OIDC provider and associate it with the cluster 

	eksctl utils associate-iam-oidc-provider --region us-east-2 --cluster demo-flask --approve
	
#	Create an IAM policy afor the ALB ingress controller	

	aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicy \
    --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.5/docs/examples/iam-policy.json

#	Create a Kubernetes service account

	kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.5/docs/examples/rbac-role.yaml
	
#	Create an IAM service account for the ALB ingress controller

	eksctl create iamserviceaccount \
    	--region us-east-2 \
    	--name alb-ingress-controller \
    	--namespace kube-system \
    	--cluster demo-flask \
    	--attach-policy-arn arn:aws:iam::$$(aws sts get-caller-identity --query Account --output text):policy/ALBIngressControllerIAMPolicy \
    	--override-existing-serviceaccounts \
    	--approve

#	Deploy the ALB Ingress Controller	
	
	kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.5/docs/examples/alb-ingress-controller.yaml
