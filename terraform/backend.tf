terraform {
  backend "s3" {
    bucket = "artifact-peter"
    key    = "terraform1/portfolio-site/state.tfstate"
    region = "us-east-1"
  }
}
