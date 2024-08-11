#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -g ResourceGroup -l Location -s Source"
    exit 1
}

# Parse command line arguments
while getopts "g:l:s:" opt; do
    case $opt in
        g) RESOURCE_GROUP_NAME=$OPTARG ;;
        l) LOCATION=$OPTARG ;;
        s) SOURCE=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if all parameters are provided
if [ -z "$RESOURCE_GROUP_NAME" ] || [ -z "$LOCATION" ] || [ -z "$SOURCE" ]; then
    echo "Error: Both ResourceGroup, Location and Source parameters are required."
    usage
fi

# Your script logic here
echo "ResourceGroup: $RESOURCE_GROUP_NAME"
echo "Location: $LOCATION"
echo "Source: $SOURCE"

# Change directory to the source folder, zip its contents, and go back
cd $SOURCE && \
zip -r ../publish.zip . && \
cd ..

# Deploy the zipped application to the Azure Web App
APPSERVICE_NAME=$RESOURCE_GROUP_NAME"-appservice"
az webapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APPSERVICE_NAME \
    --src publish.zip

echo "ASP.NET Core Web API deployed to Azure Web App '$APPSERVICE_NAME' successfully."
