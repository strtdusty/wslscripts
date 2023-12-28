#!/usr/bin/env bash
GREEN="\e[32m"
NC="\e[0m"

organization_name=${1}
printf "${GREEN}Organization name: ${organization_name}${NC}\n"
if [ -z "$organization_name" ]; then
    printf "${GREEN}Organization name not set.  Pass in an organization name, exiting...${NC}\n"
    exit 1
fi

#Install the AZ cli if it is not installed
if ! az --version; then
    printf "${GREEN}Installing AZ cli...${NC}\n"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

#Detect if the user is logged in to the AZ cli
if ! az account show; then
    printf "${GREEN}Not logged into the CLI, trying now...${NC}\n"
    az login --use-device-code
fi

#Detect if the user has a variable named ${organization_name}_ARTIFACTS_PAT is set in the .bashrc file
if ! grep "${organization_name}_ARTIFACTS_PAT" ~/.bashrc; then
    printf "${GREEN}${organization_name}_ARTIFACTS_PAT not set, trying to set it now...${NC}\n"
    scopes="vso.packaging"
    pat_name=${2-"auto-generated-by-setup-for-dev-containers.sh"}
    #make it valid for 364 days
    valid_to=$(date -u -d "364 days" '+%Y-%m-%dT%H:%MZ')
    
    uri="https://vssps.dev.azure.com/$organization_name/_apis/Tokens/Pats?api-version=6.1-preview"
    resource="https://management.core.windows.net/"
    body="{ \"displayName\": \"$pat_name\", \"scope\": \"$scopes\", validTo: \"$valid_to\" }"
    headers="Content-Type=application/json"

    printf "${GREEN}creating the Personal Access Token '$pat_name' in the Azure DevOps organization '${organization_name}'\n"

    token=$(az rest \
    --method post \
    --uri "$uri" \
    --resource "$resource" \
    --body "$body" \
    --headers "$headers" \
    --query "patToken.token" \
    --output tsv) || exit_with_error "unable to create Personal Access Token in Azure DevOps organization '${organization_name}'"

    #Write the PAT to the .bashrc file
    echo "export ${organization_name}_ARTIFACTS_PAT=$token" >> ~/.bashrc

    #Reload the .bashrc file
    source ~/.bashrc

    printf "${GREEN}PAT created successfully: ${token}${NC}\n"
else
    printf "${GREEN}${organization_name}_ARTIFACTS_PAT already set, skipping...${NC}\n"
fi
