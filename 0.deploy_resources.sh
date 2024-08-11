#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -g ResourceGroup -l Location -p DatabasePassword"
    exit 1
}

# Parse command line arguments
while getopts "g:l:p:" opt; do
    case $opt in
        g) RESOURCE_GROUP_NAME=$OPTARG ;;
        l) LOCATION=$OPTARG ;;
        p) DB_PASSWORD=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if both parameters are provided
if [ -z "$RESOURCE_GROUP_NAME" ] || [ -z "$LOCATION" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Both ResourceGroup, Location and DatabasePassword parameters are required."
    usage
fi

# Your script logic here
echo "ResourceGroup: $RESOURCE_GROUP_NAME"
echo "Location: $LOCATION"

# Create a new resource group using Azure CLI
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION

# Provision App Service Plan
APPSERVICE_PLAN_NAME=$RESOURCE_GROUP_NAME"-appserviceplan"
az appservice plan create \
    --name $APPSERVICE_PLAN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --is-linux \
    --sku F1  # Free tier

# Provision App Service
APPSERVICE_NAME=$RESOURCE_GROUP_NAME"-appservice"
az webapp create \
    --name $APPSERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APPSERVICE_PLAN_NAME \
    --runtime "DOTNETCORE:8.0"
    
az webapp cors add \
    --name $APPSERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --allowed-origins '*'

# Provision Azure SQL Database
SQL_SERVER_NAME=$RESOURCE_GROUP_NAME"-sql-server"
SQL_SERVER_ADMIN_USER="AdminUser"
SQL_DATABASE_NAME=$RESOURCE_GROUP_NAME"-sql-db"
az sql server create \
    --name $SQL_SERVER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --admin-user $SQL_SERVER_ADMIN_USER \
    --admin-password $DB_PASSWORD

# Allow Azure services to connect to the SQL server
az sql server firewall-rule create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER_NAME \
    --name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

az sql db create \
    --name $SQL_DATABASE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER_NAME \
    --edition Basic

# Get the connection string
SQL_CONNECTION_STRING="Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DATABASE_NAME;Persist Security Info=False;User ID=$SQL_SERVER_ADMIN_USER;Password=$DB_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Set the connection string for the Web App
az webapp config connection-string set \
    --name $APPSERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --settings "TodosDatabase=$SQL_CONNECTION_STRING" \
    --connection-string-type SQLAzure

# Output the resource group name for future reference
echo "Resource Group Name: $RESOURCE_GROUP_NAME"
