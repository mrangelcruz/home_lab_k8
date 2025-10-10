# home_lab_k8

## Launch cluster via Terraform

    terr init
    terr fmt
    terr validate
    terr plan
    terr apply -auto-approve

The terraform state is uploaded to S3, and tfstate lock is regsitered in dynamodb, both in us-west-2 region.