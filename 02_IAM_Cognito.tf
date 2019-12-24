resource "aws_cognito_identity_pool" "identPool" {
  identity_pool_name               = "request form pool"
  allow_unauthenticated_identities = true
}

resource "aws_iam_role" "unauthenticated" {
  name = "cognito_ddbAccount_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Federated": "cognito-identity.amazonaws.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity"
      }
    ]
  }
EOF
}


resource "aws_iam_role_policy" "unauthenticated" {
  name = "authenticated_policy"
  role = "${aws_iam_role.unauthenticated.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

//Pool setup attachment
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = "${aws_cognito_identity_pool.identPool.id}"
  roles {
    "authenticated" = "${aws_iam_role.unauthenticated.arn}"
    "unauthenticated" = "${aws_iam_role.unauthenticated.arn}"
  }
}
