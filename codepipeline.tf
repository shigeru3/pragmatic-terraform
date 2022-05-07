data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GEtBucketVersioning",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

module "codepipeline_role" {
  source = "./iam_role"
  name = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_s3_bucket" "artifact" {
  bucket = "artifact-pragmatic-shigeru-terraform"

  lifecycle_rule {
    enabled = true
    expiration {
      days = "180"
    }
  }
}

resource "aws_codepipeline" "example" {
  name     = "example"
  role_arn = module.codepipeline_role.iam_role_arn
  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      category = "Source"
      name     = "Source"
      owner    = "ThirdParty"
      provider = "GitHub"
      version  = 1
      output_artifacts = ["Source"]

      configuration = {
        Owner = "shigeru3"
        Repo = "pragmatic-terraform"
        Branch = "main"
        PollForSourceChanges = false
      }
    }
  }
  stage {
    name = "Build"
    action {
      category = "Build"
      name     = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      input_artifacts = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.example.id
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      name     = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = aws_ecs_cluster.example.name
        ServiceName = aws_ecs_service.example.name
        FileName = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_codepipeline_webhook" "example" {
  name = "example"
  target_pipeline = aws_codepipeline.example.name
  target_action = "Source"
  authentication = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = "VerRandomStringMoreThan20Byte"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

provider "github" {
  organization = "shigeru3"
}

resource "github_repository_webhook" "example" {
  events     = ["push"]
  repository = "pragmatic-terraform"
  configuration {
    url = aws_codepipeline_webhook.example.url
    secret = "VeryRandomStringMoreThan20Byte"
    content_type = "json"
    insecure_ssl = false
  }
}
