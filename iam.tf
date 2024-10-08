data "aws_iam_policy" "AmazonSSMFullAccess" {
  name = "AmazonSSMFullAccess"
}


resource "aws_iam_role" "sessionmanager-role" {
  name               = "AWSSessionManagerRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "policy-attachment" {
  role       = aws_iam_role.sessionmanager-role.name
  policy_arn = data.aws_iam_policy.AmazonSSMFullAccess.arn
}


resource "aws_iam_instance_profile" "AWSSessionManagerProfile" {
  name = "AWSSessionManagerProfile"
  role = aws_iam_role.sessionmanager-role.name
}
