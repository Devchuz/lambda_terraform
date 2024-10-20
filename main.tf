terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.region
}

# Variables locales para la ruta del archivo requirements.txt y el directorio de librerías
locals {
  lambda_layer_root             = "${path.module}/lambda_layer"          # Directorio raíz de la capa
  lambda_runtime                = "python3.9"
  lambda_function_name          = "my_lambda_function"
  extra_tag                     = "extra-tag"
}

# Recurso: Rol para la función Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Recurso: Archivar la capa Lambda
data "archive_file" "lambda_layer" {
  type        = "zip"
  source_dir  = local.lambda_layer_root   # Directorio de la capa
  output_path = "${path.module}/lambda_layer.zip"
}

# Recurso: Crear la versión de la capa Lambda con las dependencias
resource "aws_lambda_layer_version" "layer" {
  layer_name          = "${local.lambda_function_name}-pip-requirements"
  filename            = data.archive_file.lambda_layer.output_path
  source_code_hash    = data.archive_file.lambda_layer.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]

  lifecycle {
    create_before_destroy = true
  }
}

# Recurso: Función Lambda
resource "aws_lambda_function" "example" {
  for_each = var.service_names

  function_name = "lambda_function_${each.key}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = local.lambda_runtime

  filename         = "src/lambda_function.zip"
  source_code_hash = filebase64sha256("src/lambda_function.zip")

  # Vincular la función Lambda con la capa recién creada
  layers = [
    aws_lambda_layer_version.layer.arn
  ]

  tags = {
    ExtraTag = local.extra_tag
    Name     = "Lambda-${each.key}"
  }

  environment {
    variables = {
      ENVIRONMENT = "test"
      SERVICE     = each.key
    }
  }

  depends_on = [aws_lambda_layer_version.layer]
}
