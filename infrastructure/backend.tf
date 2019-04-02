terraform {
  backend "gcs" {
    //    prefix  = ""
    //    bucket  = "" #these will be passed as backend-config variables in the terraform init. See cloubuild.yaml.
    //    project = ""
  }
}