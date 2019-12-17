# Definimos ruta de los estáticos
variable "website-dir" {
  default = "../../../website/"
}

# Definimos tipos MIME
variable "mime_types" {
  default = {
    html = "text/html"
    css = "text/css"
    jpg = "image/jpeg"
    png = "image/png"
  }
}

# Creamos bucket S3 orientado a servir estáticos
resource "aws_s3_bucket" "emili-darder-website" {
  bucket = "emili-darder-cracks"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name  = "Emili Darder - Website"
    Class = "Máquinas"
  }
}

# Busca cada uno de los ficheros estáticos y los sube al bucket
resource "aws_s3_bucket_object" "static-content" {
  for_each      = fileset(var.website-dir, "**/*.*") 
  bucket        = aws_s3_bucket.emili-darder-website.bucket
  key           = replace(each.value, var.website-dir, "")   #<--- nombre del fichero en bucket
  source        = "${var.website-dir}${each.value}"          #<--- fichero origen
  acl           = "public-read"
  etag          = filemd5("${var.website-dir}${each.value}")
  content_type  = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1])
}

