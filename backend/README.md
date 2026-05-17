# User guide

This guide walks you through setting up the backend from scratch.

## Prerequisites

Make sure you have the following:

- The repository cloned to your machine
- PostgreSQL running locally or accessible remotely
- Redis running locally or accessible remotely

You should be inside the *backend/* directory:

```bash
cd the-walking-dead-hub/backend
````

Also create a *.env* file with the following entries:

```env
database_host=
database_port=
database_username=
database_password=
database_name=

redis_host=
redis_port=
redis_db=
redis_password=
```

Example:

```env
database_host=localhost
database_port=5432
database_username=postgres
database_password=postgres
database_name=twd_character_stats

redis_host=localhost
redis_port=6379
redis_username=default
redis_password=
redis_name=0
```

## Running locally

1. Make sure Poetry is in your machine's PATH variable.

2. Install project's dependencies:

```bash
poetry install
```

3. Install the scraper's required browser:

```bash
poetry run playwright install chromium
```

4. Run database migrations to create all tables and populate some base data (e.g. enums and reference tables):

```bash
poetry run alembic upgrade head
```

5. Populate the remaining data via scraping:

```bash
poetry run python -m twd_hub.scripts.initialize_db
```

This step will:

* Fetch data from external sources
* Populate characters, episodes, and appearances
* Complete the database


Optionally, to speed up future runs, you can cache downloaded HTML pages:

```bash
poetry run python -m twd_hub.scripts.initialize_db --cache-dir .tmp
```

This will save scraped HTML locally to avoid re-downloading data and make subsequent runs much faster.

6. Once the database is fully populated, you can run queries like:

```sql
select 
	ep.season,
	ep.number,
	ep.name as "episode",
	en.name as "who",
	apt.name as type,
	apft.name as form
from appearances ap
join episodes ep on ep.id = ap.episodeid
join entities en on en.id = ap.entityid
join appearancetypes apt on apt.id = ap.appearancetypeid 
left join appearanceforms apf on apf.appearanceid = ap.id
left join appearanceformtypes apft on apft.id = apf.appearanceformtypeid;
```

This query shows episode info (season, number, name), character involved, type of appearance and form of appearance (if applicable).

## Running on a container

1. Make sure Docker is in your machine's PATH variable.

2. Build the application image:

```bash
docker build -t twd_uvicorn:latest -f Dockerfile.api .
```

3. Run database migrations inside the container:

```bash
docker run --rm --env-file .env.docker twd_uvicorn alembic upgrade head
```

4. Build the database initialization image:

```bash
docker build -t twd_dbinit:latest -f Dockerfile.dbinit .
```

5. Initialize the database:

```bash
docker run --rm --env-file .env.docker twd_dbinit
```

5. Run the application:

```bash
docker run -d --env-file .env.docker -p 5000:5000 --name twd_uvicorn twd_uvicorn:latest
```

## Running on cloud

This section will document everything from scratch to deploy the FastAPI back-end to Azure.

The following variables are going to be used through this tutorial:

- `PROJECT_ID`: the name of your project
- `PROJECT_LOCATION`: where do you want your project's container to be stored (using `eastus`)
- `GITHUB_USERNAME`: the GitHub account's username used to deploy the containers

### Azure setup

1. Check if you have the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed:

```shell
az --version
```
```lang-none
azure-cli                         2.86.0

core                              2.86.0
telemetry                          1.1.0

Dependencies:
msal                              1.35.1
azure-mgmt-resource               24.0.0

Python location 'C:\...\python.exe'
Config directory 'C:\...\.azure'
Extensions directory 'C:\...\cliextensions'

Python (Windows) 3.13.13 (tags/v3.13.13:01104ce, Apr  7 2026, 19:25:48) [MSC v.1944 64 bit (AMD64)]

Legal docs and information: aka.ms/AzureCliLegal


Your CLI is up-to-date.
```

2. Log in into your Azure account:

```shell
az login
```

This command will first open your browser to the sign-in page where you complete authentication.

Then it'll show your current list of subscriptions: choose which one you would like to use for this project.

3. Create a resource group for your project:

```shell
az group create --name PROJECT_ID-rg --location PROJECT_LOCATION
```
```lang-none
{
  "id": "/subscriptions/99999999-9999-9999-9999-999999999999/resourceGroups/PROJECT_ID-rg",
  "location": "PROJECT_LOCATION",
  "managedBy": null,
  "name": "PROJECT_ID-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

4. Create a identity for your project:

```shell
az identity create --resource-group PROJECT_ID-rg --name PROJECT_ID-identity
```
```lang-none
{
  "clientId": "99999999-9999-9999-9999-999999999999",
  "id": "/subscriptions/99999999-9999-9999-9999-999999999999/resourcegroups/PROJECT_ID-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/PROJECT_ID-identity",
  "isolationScope": "None",
  "location": "PROJECT_LOCATION",
  "name": "PROJECT_ID-identity",
  "principalId": "99999999-9999-9999-9999-999999999999",
  "resourceGroup": "PROJECT_ID-rg",
  "systemData": null,
  "tags": {},
  "tenantId": "99999999-9999-9999-9999-999999999999",
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}
```

#### Container Apps setup

1. Enable the Container Apps extension:

```shell
az extension add --name containerapp
```
```lang-none
No stable version of 'containerapp' to install. Preview versions allowed.
The installed extension 'containerapp' is in preview.
```

If you have already enabled:

```shell
az extension update --name containerapp
```
```lang-none
No stable version of 'containerapp' to install. Preview versions allowed.
Latest version of 'containerapp' is already installed.

Use --debug for more information
```

2. Enable the providers needed for Container Apps:

```shell
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
```

3. Create a Container App environment:

```shell
az containerapp env create
  --name PROJECT_ID-env
  --resource-group PROJECT_ID-rg
  --location PROJECT_LOCATION
```
```lang-none
The behavior of this command has been altered by the following extension: containerapp
No Log Analytics workspace provided.
Generating a Log Analytics workspace with name "workspace-PROJECT_IDXXXXXXX"

Container Apps environment created. To deploy a container app, use: az containerapp create --help
```

#### Key Vault setup

1. Enable the providers needed for Key Vault:

```shell
az provider register --namespace Microsoft.KeyVault
```

2. Create a new Key Vault:

```shell
az keyvault create 
  --name PROJECT_ID-kv
  --resource-group PROJECT_ID-rg
  --location PROJECT_LOCATION
```

3. Query the Key Vault ID:

```shell
az keyvault show --name PROJECT_ID-kv --query id --output tsv
```

The output will be refered as `PROJECT_KEYVAULT_ID`.

4. Query your account ID:

```shell
az ad signed-in-user show --query id --output tsv
```

The output will be refered as `AZURE_USERID`.

5. Give yourself permission to create and update secrets:

```shell
az role assignment create 
  --assignee AZURE_USERID
  --role "Key Vault Administrator"
  --scope PROJECT_KEYVAULT_ID
```

6. Add the secrets required for the project:

```shell
az keyvault secret set
  --vault-name PROJECT_ID-kv
  --name DATABASE-PASSWORD
  --value "XXXXXXXXXXXXX"
```

Note that the secret name must be declared with a slash,
even if a underscore is being used on the code.

7. Query the managed identity's account ID:

```shell
az identity show 
  --name PROJECT_ID-identity
  --resource-group PROJECT_ID-rg
  --query principalId
  --output tsv
```

The output will be refered as `PROJECT_IDENTITY_ACCOUNT_ID`.

8. Give the managed identity's account permission to read secrets:

```shell
az role assignment create 
  --assignee PROJECT_IDENTITY_ACCOUNT_ID
  --role "Key Vault Secrets User"
  --scope PROJECT_KEYVAULT_ID
```

### GHCR setup

Azure Container Apps needs a container URL it can pull. For that
GitHub Container Registry (GHCR) will be used.

1. Create a personal access token on https://github.com/settings/tokens.

The option is "Generate new token (classic)".

The token name may be `PROJECT_ID-ghcr`.

The minimal permissions are `repo` (and its children), `write:packages` (and its children) and `delete:packages`.

The created token will be refered as `GITHUB_TOKEN`.

2. Login to your GitHub account via Docker:

```shell
docker login ghcr.io -u GITHUB_USERNAME
```

Type the token as the password.

### Deploy

1. Change your current working directory to _backend/_.

2. Build your image locally:

```shell
docker build -t PROJECT_ID-api -f Dockerfile.api .
```

3. Tag your image:

```shell
docker tag PROJECT_ID-api ghcr.io/GITHUB_USERNAME/PROJECT_ID-api:v1
```

4. Push it to GitHub:

```shell
docker push ghcr.io/GITHUB_USERNAME/PROJECT_ID-api:v1
```

5. Query the managed identity (created on step 4 of **Azure setup**) ID:

```shell
az identity show
  --name PROJECT_ID-identity
  --resource-group PROJECT_ID-rg
  --query id 
  --output tsv
```

The output will be refered as `PROJECT_IDENTITY_ID`.

6. Deploy to Azure:

```shell
az containerapp create
  --name PROJECT_ID-api
  --resource-group PROJECT_ID-rg
  --environment PROJECT_ID-env
  --image ghcr.io/GITHUB_USERNAME/PROJECT_ID-api:v1
  --target-port 5000
  --ingress external
  --min-replicas 0
  --max-replicas 1
  --registry-server ghcr.io
  --registry-username GITHUB_USERNAME
  --registry-password GITHUB_TOKEN
  --user-assigned PROJECT_IDENTITY_ID
  --secrets 
      database-password="keyvaultref:https://PROJECT_ID-kv.vault.azure.net/secrets/DATABASE-PASSWORD,identityref:PROJECT_IDENTITY_ID"
  --set-env-vars
      DATABASE_HOST="db.example.org"
      DATABASE_PORT=5432
      DATABASE_USERNAME="username"
      DATABASE_PASSWORD=secretref:database-password
      DATABASE_NAME="dbname"
      REDIS_HOST="redis.example.org"
      REDIS_PORT=6379
      REDIS_USERNAME=default
      REDIS_PASSWORD=""
      REDIS_NAME=0
```
```lang-none
The behavior of this command has been altered by the following extension: containerapp
Adding registry password as a secret with name "ghcrio-GITHUB_USERNAME"

Container app created. Access your app at https://PROJECT_ID-api.XXXXXXXXXXXXXXX-9999999999.PROJECT_LOCATION.azurecontainerapps.io/
```

Note that the `--target-port` argument must be the same as the exposed by the _Dockerfile.api_.

### Integrating with GitHub Actions

1. Create a new Active Directory application:

```shell
az ad app create --display-name "github-actions-containerapp"
```

2. Query the application ID:

```shell
az ad app list
  --display-name github-actions-containerapp
  --query "[].{appId:appId}"
  --output tsv
```

The output will be refered as `AZURE_CLIENT_ID`.

3. Create the service principal account:

```shell
az ad sp create --id AZURE_CLIENT_ID
```

4. Create the federated credential associated with the app:

```shell
az ad app federated-credential create
  --id AZURE_CLIENT_ID
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:GITHUB_USERNAME/GITHUB_PROJECT_REPOSITORY:environment:production",
    "audiences": [
      "api://AzureADTokenExchange"
    ]
  }'
```

5. Query the resource group ID:

```shell
az group show --name PROJECT_ID-rg --query id --output tsv
```

The output will be refered as `PROJECT_RESOURCE_GROUP_ID`.

6. Give Contributor permissions to the app:

```shell
az role assignment create 
  --assignee AZURE_CLIENT_ID
  --role "Contributor"
  --scope PROJECT_RESOURCE_GROUP_ID
```

7. Query your account's tenant ID:

```shell
az account show --query tenantId --output tsv
```

The output will be refered as `AZURE_TENANT_ID`.

8. Query your account's subscription ID:

```shell
az account show --query id --output tsv
```

The output will be refered as `AZURE_SUBSCRIPTION_ID`.

9. Add the `AZURE_*_ID` variables to your GitHub secrets.

10. Look at the _.github/workflows/backend-deploy.yaml_ to learn how to use these variables.
