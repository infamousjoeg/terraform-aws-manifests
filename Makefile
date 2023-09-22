default: help

.PHONY: help
## Prints this help message
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-\_0-9%:\\]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
		helpCommand = $$1; \
		helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	gsub("\\\\", "", helpCommand); \
	gsub(":+$$", "", helpCommand); \
		printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"

.PHONY: all
## terraform apply all Terraform Manifests
all: jenkins/apply

########## JENKINS ##########

.PHONY: jenkins/init
## terraform init on Jenkins
jenkins/init:
	@echo "+ Initializing Jenkins..."
	@echo ""
	@cd tf_deploy/jenkins && terraform init

.PHONY: jenkins/validate
## terraform validate on Jenkins
jenkins/validate:
	@echo "+ Validating Jenkins..."
	@echo ""
	@cd tf_deploy/jenkins && terraform validate

.PHONY: jenkins/plan
## terraform plan on Jenkins
jenkins/plan: jenkins/init jenkins/validate
	@echo "+ Planning Jenkins..."
	@echo ""
	@cd tf_deploy/jenkins && summon -p ring.py terraform plan

.PHONY: jenkins/apply
## terraform apply on Jenkins
jenkins/apply: jenkins/init jenkins/validate
	@echo "+ Deploying Jenkins into AWS EC2..."
	@echo ""
	@cd tf_deploy/jenkins && summon -p ring.py terraform apply -auto-approve

.PHONY: jenkins/destroy
## terraform destroy on Jenkins
jenkins/destroy:
	@echo "+ Destroying Jenkins..."
	@echo ""
	@cd tf_deploy/jenkins && summon -p ring.py terraform destroy -auto-approve