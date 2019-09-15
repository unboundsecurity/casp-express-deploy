openssl genrsa 2048 > key.pem
openssl rsa -in key.pem -pubout > casp_backup.pem
terraform init
terraform destroy -auto-approve
terraform apply