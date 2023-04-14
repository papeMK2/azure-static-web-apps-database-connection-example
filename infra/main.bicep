targetScope =  'subscription'

@minLength(1)
@maxLength(64)
param environmentName string

@minLength(1)
param location string

param sqlServerName string = ''
param databaseName string = ''

param localEnvIpAddress string

@secure()
param sqlAdminPassword string
@secure()
param appUserPassword string

var tags = { 'azd-env-name': environmentName }
var suffix = guid('guid')

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module sqlServer 'app/db.bicep' = {
  name: 'sql'
  scope: rg
  params: {
    name: !empty(sqlServerName) ? sqlServerName : 'sql-${suffix}'
    databaseName: databaseName
    location: location
    localEnvIpAddress: localEnvIpAddress
    sqlAdminPassword: sqlAdminPassword
    appUserPassword: appUserPassword
    tags: tags
  }
}
