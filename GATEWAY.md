# Minio Gateway

This details the required setup and configuration to run Minio gateway to supported cloud providers.

## Google Cloud Storage

1. Navigate to the [API Console Credentials page](https://console.developers.google.com/project/_/apis/credentials).
2. Select a project or create a new project. Note the project ID.
3. Select the Create credentials dropdown on the Credentials page, and click Service account.
4. Populate the Service account name and Service account ID and click "Create and continue"
5. In the "Select a role" dropdown, type "Storage Admin" and select that option from the list
6. Click on "Done" to create the service account
7. Click on the created service account
8. Click on "Keys" tab -> Add key -> Create new key
9. Choose Key type: JSON and click Create
10. Keep the downloaded JSON file safe, it contains your credentials

To configure the minio instance you will need the project ID and the credentials JSON.

## Azure Blob Storage

1. Follow [this guide](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal) to create an Azure Storage Account
2. Access the created storage account, click on "Access Keys" under "Security + Networking"
3. Note the storage account name
3. Click on "Show Keys" to see the storage account key

To configure the minio instance you will need the Storage account name and a key.

## AWS S3

1. In the AWS Console: navigate to [IAM Users](https://console.aws.amazon.com/iamv2/home?#/users)
2. Click on "Add User"
3. Input User Name and select Programattic Access
4. Click on "Next: Permissions"
5. Click on "Attach existing policies directly"
6. In the policies search box input "AmazonS3FullAccess" and mark the checkbox next to that policy
7. Click "Next", "Next" then on "Create User"
8. Copy the access key and secret

To configure the minio instance you will need the user's access key and secret.
