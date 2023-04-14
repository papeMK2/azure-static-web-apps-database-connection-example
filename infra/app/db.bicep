param name string
param location string = resourceGroup().location
param tags object = {}

param databaseName string = ''
param localEnvIpAddress string = ''

@secure()
param sqlAdminPassword string

@secure()
param appUserPassword string

var defaultDatabaseName = 'Todo'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module sqlServer '../core/database/sqlserver/sqlserver.bicep' = {
  name: 'sqlserver'
  params: {
    name: name
    location: location
    tags: tags
    databaseName: actualDatabaseName
    sqlAdminPassword: sqlAdminPassword
    appUserPassword: appUserPassword
    localEnvIpAddress: localEnvIpAddress
  }
}

output connectionString string = sqlServer.outputs.connectionString
output databaseName string = sqlServer.outputs.databaseName
