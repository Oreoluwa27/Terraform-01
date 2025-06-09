resource "aws_s3_bucket" "storage" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}
