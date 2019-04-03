# A GCP-based CI/CD Template For Deploying a Static Website to AWS

## What is this for?

This repo is intended to provide a pattern or template for anyone wishing to create a [CI/CD](https://en.wikipedia.org/wiki/CI/CD) pipeline in GCP for a version controlled static website, deployed to AWS.

If you want to rapidly get a static site up and running use best practises, then this template is for you.

Features:
* CDN Hosting
* Content served over HTTP2 ([which can be faster](https://www.oreilly.com/ideas/will-http2-make-my-site-faster))
* Content managed using [gitflow](https://datasift.github.io/gitflow/IntroducingGitFlow.html)
* Automatic creation of new environments based on feature branch


## Who Am I?

My name is [Chris Priest](https://chrisprie.st), and I am a Senior Consultant working for Cloud-first Consultancy [Amido](https://amido.com).

## Why...
 
### ...AWS for the static site?

AWS provides a world-class infrastructure for hosting static sites ([S3](https://aws.amazon.com/s3/)), including a huge CDN ([CloudFront](https://aws.amazon.com/cloudfront/)) that supports HTTP2, where certificates are automatically managed. It is very cost effective to run, and serverless. TODO linke serverless to Paul Johnston's definition on twitter.

This means that sites hosted like this are served fast, and they are secure, which is good for SEO.

### ...Google Cloud Build for the build?

GBP's build system ([Google Cloud Build](https://cloud.google.com/cloud-build/)) does not have the fanciest of UIs, nor does it come with a nice UI for configuring every build step. But it does come with a generous free allowance (of 120 minutes per day), a high level of configurability (which is inherently IaaC), and it is fast.

## Origins

This template was forged from the sweat, tears & lessons learned of deploying the [author's own website](https://chrisprie.st), a static site that is optimised for load performance.

## Deployment Topology

TODO

## Prerequisites 

* Access to a GCP Account (if you don't have one, you can get [$300 free credit](https://cloud.google.com/free/) for the first 12 months)
* An AWS Account
* A git repo
* The [Google Cloud SDK]((https://cloud.google.com/sdk/install)) installed (don't forget to run `gcloud init`)

## How is this achieved?

There are several components to the CI/CD pipeline created with this template.

### Google Cloud Build

Google Cloud Build provides the compute and build infrastructure required to process our CI/CD pipeline. 

### Google Cryptographic Keys / Key Management Service

TODO (AWS & GCS creds)

### Google Cloud Storage

TODO (terraform state)

TODO: Why use GCP Cloud Storage and not AWS S3? Because GCP Cloud Storage supports locking, which we need to ensure against lost update problems.

### Terraform

Terraform is driven by Google Cloud Build and is responsible for configuring infrastructure in AWS. Support is provided by a custom Terraform Cloud Builder, which has the addition of the `jq` tool for processing terraform output data for use downstream.

### AWS CLI

The AWS CLI is used to sync the static site data between the build artifacts and the appropriate S3 bucket.

## How to use this template

### Useful links
* [Google Cloud Platform Console](https://console.cloud.google.com)
* AWS Console

### What you will need to know beforehand
* Your GCP project ID (you can get this by running a `gcloud projects list` to get a list of your projects & their corresponding IDs)

TODO table with what we'll use for examples?

| Thing you'll need to know | Where to get it | What used in below steps |
| --- | --- | --- |
| GCP Project ID | Either `gcloud projects list` on the command line or look in the project drop down list at the top of the GCP Console | `test-1-236419` |
| GCP Cloud Build Service Account Name | It appears that the only way to get the account name is to go to the GCP Console > IAM & Admin > IAM and copy out the member name | `1027676702318@cloudbuild.gserviceaccount.com` |

### Steps

These steps should be enough to take you from nothing to a fully working GCP Cloud Build CI/CD pipeline deploying a 'hello world' website.

1. Make sure you have a Project in your GCP account. If you don't already have one for this particular application, [create one](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
1. In the GCP Console, under your Project, Enable various APIs by going to APIs & Services > Library and searching for, and enabling, the following APIs:
    1. Cloud Build API
    1. Cloud Key Management Service (KMS) API
1. Create a Google Cloud Storage bucket for storing Terraform state
    1. In the GCP Console, go to Storage, and create a new bucket
    1. The parameters of the bucket (storage class, access control model etc) aren't necessarily of concern. If you are worried, just go with the defaults
    1. Make a note of the name of the bucket, you'll need it later
1. Create Google Cloud Key Management Service (KMS) Key Rings & CryptoKeys for GCS & AWS
    1. Create a key ring for GCS: `gcloud kms keyrings create gcs --location=global`
    1. Create a `deploy` key for deploying with GCS: `gcloud kms keys create deploy --location=global --keyring=gcs --purpose=encryption`
    1. Grant the Cloud Build service account access to decrypting with the key: `gcloud kms keys add-iam-policy-binding deploy --location=global --keyring=gcs --member=serviceAccount:1027676702318@cloudbuild.gserviceaccount.com --role=roles/cloudkms.cryptoKeyDecrypter`
    1. Create a key ring for AWS: `gcloud kms keyrings create aws --location=global`
    1. Create a `deploy` key for deploying with AWS with this command `gcloud kms keys create deploy --location=global --keyring=aws --purpose=encryption`
1. Create Service Account credentials & key file for terraform to use to access state in the GCS bucket
    1. Create the new service account: `gcloud iam service-accounts create terraform-state`
    1. Assign the Storage Object Admin role to the service account: `gcloud projects add-iam-policy-binding test-1-236419 --member "serviceAccount:terraform-state@test-1-236419.iam.gserviceaccount.com" --role "roles/storage.objectAdmin"`
    1. Generate the key file: `gcloud iam service-accounts keys create gcs-terraform-state-credentials.json --iam-account terraform-state@test-1-236419.iam.gserviceaccount.com`. **Keep the generated `gcs-terraform-state-credentials.json` file safe!**
1. Encrypt the GCS bucket key file using the previously generated CryptoKey for GCS
    1. Encrypt the file: `gcloud kms encrypt --plaintext-file=gcs-terraform-state-credentials.json --ciphertext-file=gcs-terraform-state-credentials.json.enc --location=global --keyring=gcs --key=deploy`
    1. Destroy the original: `rm gcs-terraform-state-credentials.json`
1. Create a Google Cloud Build trigger
    1. In the GCP Console, go to Triggers and create a trigger
    1. Choose your source repository hosting option. This template has only been tested with Github, but I suspect that other hosting options will not be problematic
    1. Authenticate, select your repo.
    1. For Trigger settings, take note of your selections, but you can likely leave almost all settings as their default. Be sure to change the Build configuration to `Cloud Build configuration file (yaml or json)` and change the Cloud Build configuration file location to `/cloudbuild.json`
    1. Click Create Trigger to complete the trigger creation process
1. 
    
1. Create a credentials file for the GCS account
1. Encrypt the  
1. foods

### Configuration

The CI/CD pipeline is configured in `cloudbuild.json` in the root of your repo.

Things that you will need to configure:

| Configuration Item | Description |
| --- | --- |
| _TF_STATE_BUCKET | The name of the GCP Storage bucket that will be used to store Terraform state |
| 

1. Configure the name of the GCS bucket that will be used to store Terraform state
1. 