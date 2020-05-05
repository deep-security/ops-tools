
# AWS Terraform Support

## AWS Connector via Terraform
Some organizations may not want to use AWS Cloudformation to connect their AWS account to **Trend Micro Deep Security Manager**. To help allow other methods to do this, we can use **Terraform** to provision the connection. This terraform code will create the following:
* An IAM role with access to:
  - Creates a role with cross-account access to Deep Security as a Service Account ID: 147995105371
  - Policy for the role with read access to AWS EC2, Workspaces, and IAM.

## Requirements

There are a couple variables that are required to be entered when applying:

```
environment
external_id
```

The **externalID** can be found within Deep Security Manager if you go to **Computers** at the top. Click **Add** -> **Add AWS Account**. A wizard will appear, select **Advanced** as the setup type and click **Next**. Then click the eye icon next to the obscured *externalID* to reveal it.

**Copy the external ID to a secure place as you will need it when applying the terraform code.**

## Usage

1. Apply the terraform code to your AWS account. If the code was applied successfully, Terraform will output the Role ARN for you to copy into Deep Security Manager.

Example output:
```
aws_iam_role_policy_attachment.tmds_role_policy_attachment: Creation complete after 1s [id=dev-trend-micro-deep-security-20200505204655560300000001]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

trend_micro_aws_iam_role_arn = arn:aws:iam::{YOUR_AWS_ACCOUNT_ID}:role/dev-trend-micro-deep-security
```

2. Copy the Role ARN from the output and go in to Deep Security Manager.

3. Once you are logged in to Deep Security Manager, go to the **Computers** at the top. 

4. Next, you will select **Add** -> **Add AWS Account** and a new pop up window will open. In the pop up window, select **Advanced** setup type, and click **Next**.

5. Add the Role ARN in the textbox next to Cross Account Role ARN and then selet Next.

6. Once that's done, you're all set! Go back to Deep Security Manager and click **Computers** on the top, and on the left side pane you will see your AWS account loaded into your Deep Security Manager account!
