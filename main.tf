locals {
  venv_dir       = "${path.module}/venv"
  python_version = "python3.11"
}

data "archive_file" "requirements" {
  output_path = "requirements.zip"
  source_dir  = "python"
  type        = "zip"
  depends_on  = [null_resource.install_requirements]
}

resource "null_resource" "install_requirements" {
  triggers = {
    requirements_file_changed = filebase64sha256("requirements.txt")
  }
  provisioner "local-exec" {
    command = "pip3 install -r requirements.txt -t python_dependencies/python"
  }
}

resource "aws_lambda_layer_version" "layer" {
  layer_name          = "lambda-layer-with-python-requirements"
  filename            = data.archive_file.requirements.output_path
  compatible_runtimes = [local.python_version]
}

data "archive_file" "python_code" {
  output_path = "${path.module}/script.zip"
  type        = "zip"
  source_dir  = "${path.module}/src"
}

resource "aws_lambda_function" "function" {
  function_name = "lambda-function-with-layer-requirements"
  role          = ""
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy" {
  role       = aws_iam_role.lambda_role.arn
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "lambda_name" {
  value = aws_lambda_function.function.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.function.arn
}