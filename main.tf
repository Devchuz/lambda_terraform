terraform {
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Generar un sufijo aleatorio para evitar conflictos de nombre
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# Recurso: Rol para la función Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role-${random_string.suffix.result}"  # Nombre único del rol

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

  lifecycle {
    prevent_destroy = true  # Evita destruir el recurso si ya existe
  }
}

# Adjuntar la política de logs para la función Lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Recurso: Capa Lambda para las dependencias
resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "lambda_layer.zip"
  layer_name = "lambda_layer"
  compatible_runtimes = ["python3.9"]

  source_code_hash = filebase64sha256("lambda_layer.zip")  # Hash del archivo de dependencias
}

# Recurso: Función Lambda
resource "aws_lambda_function" "example" {
  for_each = var.service_names  # Itera sobre los nombres de servicios definidos

  function_name = "lambda_function_${each.key}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.handler"  # Nombre del archivo y la función 'handler'
  runtime       = "python3.9"                # Runtime de Python 3.9

  filename         = "lambda_function.zip"  # Ruta al archivo .zip con el código de la Lambda
  source_code_hash = filebase64sha256("lambda_function.zip")  # Hash del archivo .zip

  # Referencia a la capa de Lambda que contiene las dependencias
  layers = [aws_lambda_layer_version.lambda_layer.arn]

  # Etiquetas básicas para la función
  tags = {
    Name        = "Lambda-${each.key}"
    Environment = "test"
  }

  # Variables de entorno (puedes ajustar o añadir más si es necesario)
  environment {
    variables = {
      ENVIRONMENT = "test"
      SERVICE     = each.key
    }
  }
}
