var cf = require('@mapbox/cloudfriend');

module.exports = {
AWSTemplateFormatVersion: '2010-09-09',
  Resources: {
    User: {
      Type: 'AWS::IAM::User',
      Properties: {
        Policies: [
          {
            PolicyName: 'AWS-S3-access',
            PolicyDocument: {
              Statement: [
                {
                  Action: [
                    's3:GetObject',
                    's3:GetObjectVersion',
                    's3:GetObjectAcl',
                    's3:ListBucket',
                    's3:GetBucketLocation',
                    's3:ListAllMyBuckets',
                    's3:DeleteObject',
                    's3:DeleteObjectVersion',
                    's3:PutObject',
                    's3:PutObjectAcl'
                  ],
                  Effect: 'Allow',
                  Resource: [
                      'arn:aws:s3:::mapbox',
                      'arn:aws:s3:::mapbox/*'
                  ],
                  Condition: {
                    StringLike: {
                      's3:prefix': '/vision/travis/ios-builds*'
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    },
    AccessKey: {
      Type: 'AWS::IAM::AccessKey',
      Properties: {
        UserName: cf.ref('User')
      }
    }
  },
  Outputs: {
    AccessKeyId: { Value: cf.ref('AccessKey') },
    SecretAccessKey: { Value: cf.getAtt('AccessKey', 'SecretAccessKey') }
  }
};

