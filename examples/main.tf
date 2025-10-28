provider "aws" {
  region = "eu-west-2"
}

module "template" {
  source = "../"
  # source = "github.com/ministryofjustice/cloud-platform-terraform-template?ref=version" # use the latest release

}
