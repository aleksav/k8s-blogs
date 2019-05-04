## FOR RERENENCE. Basic setup does not include any state management 
## (so if you run the terraform scripts from another machine, you will lose the current state of the cluster)
## It is best practices wit terrafrom to manage the state remotely, below if sample S3 AWS configuration
## More details here: https://www.terraform.io/docs/state/

# terraform {
#  backend "s3" {
#  encrypt = true
#  bucket = "your-state-bucket-name"
#  dynamodb_table = "your-lock-table-name"
#  region = "eu-west-1"
#  key = "tsf-k8s-blog"
#  }
# }