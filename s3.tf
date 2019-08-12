locals {
  s3_buckets = {
    "terr-www" = {
      type = ["website"]
      env = merge(local.s3_buckets_env, {})
      access = merge(local.s3_buckets_access, {
        ignore_public_acls      = false
        restrict_public_buckets = false
        block_public_acls   = false
        block_public_policy = false
      })
      website = {
        error_document = "index.html"
        index_document = "error.html"
      }
    }
    "terr-not-www" = {
      type = ["simple"]
      env = merge(local.s3_buckets_env, {})
      access = merge(local.s3_buckets_access, {})
    }
}

  s3_buckets_env = {
    request_payer = "BucketOwner"
    force_destroy = true
    versioning_enabled    = false
    versioning_mfa_delete = false
  }
  s3_buckets_access = {
    ignore_public_acls      = true
    restrict_public_buckets = true
    block_public_acls   = true
    block_public_policy = true
  }
   region = "eu-west-2"
}


resource "aws_s3_bucket" "someprojects" {
  for_each =   local.s3_buckets
  bucket         = "${terraform.workspace}-${each.key}"
  region         = local.region
  request_payer  = "BucketOwner"
  force_destroy = each.value.env.force_destroy
  tags = {
    stage = terraform.workspace
  }
  versioning {
    enabled    = each.value.env.versioning_enabled
    mfa_delete = each.value.env.versioning_mfa_delete
  }
  dynamic "website" {
    for_each =  contains(each.value.type, "website")  ? [each.value.website] : []
    content {
      error_document = each.value.website.error_document
      index_document = each.value.website.index_document
    }
  }
}

resource "aws_s3_bucket_public_access_block" "someprojects" {
  for_each =   local.s3_buckets
  bucket = "${aws_s3_bucket.someprojects["${each.key}"].id}"
  ignore_public_acls      = each.value.access.ignore_public_acls
  restrict_public_buckets = each.value.access.restrict_public_buckets
  block_public_acls   = each.value.access.block_public_acls
  block_public_policy = each.value.access.block_public_policy
}
