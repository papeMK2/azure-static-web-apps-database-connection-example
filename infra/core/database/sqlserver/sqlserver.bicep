param name string
param location string = resourceGroup().location
param tags object = {}

param appUser string = 'appUser'
param databaseName string
param sqlAdmin string = 'sqlAdmin'

@secure()
param sqlAdminPassword string

@secure()
param appUserPassword string

@secure()
param localEnvIpAddress string

resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    administratorLogin: sqlAdmin
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Enabled'
  }

  resource database 'databases' = {
    name: databaseName
    location: location
  }

  resource firewallFromAzure 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
  
  resource firewallFromLocalEnv 'firewallRules' = {
    name: 'localEnv'
    properties: {
      startIpAddress: localEnvIpAddress
      endIpAddress: localEnvIpAddress
    }
  }
}

resource sqlDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${name}-deployment-script'
  kind: 'AzureCLI'
  location: location
  properties: {
    azCliVersion: '2.37.0'
    retentionInterval: 'PT1H'
    timeout: 'PT5M'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'APPUSERNAME'
        value: appUser
      }
      {
        name: 'APPUSERPASSWORD'
        secureValue: appUserPassword
      }
      {
        name: 'DBNAME'
        value: databaseName
      }
      {
        name: 'DBSERVER'
        value: sqlServer.properties.fullyQualifiedDomainName
      }
      {
        name: 'SQLCMDPASSWORD'
        secureValue: sqlAdminPassword
      }
      {
        name: 'SQLADMIN'
        value: sqlAdmin
      }
    ]

    scriptContent: '''
    wget https://github.com/microsoft/go-sqlcmd/releases/download/v0.8.1/sqlcmd-v0.8.1-linux-x64.tar.bz2
    tar x -f sqlcmd-v0.8.1-linux-x64.tar.bz2 -C .

    cat <<SCRIPT_END > ./initDb.sql
    drop user ${APPUSERNAME}
    go
    create user ${APPUSERNAME} with password = '${APPUSERPASSWORD}'
    go
    alter role db_owner add member ${APPUSERNAME}
    go
    SCRIPT_END

    ./sqlcmd -S ${DBSERVER} -d ${DBNAME} -U ${SQLADMIN} -i ./initDb.sql
    '''
  }
}

var connectionString = 'Server=${sqlServer.properties.fullyQualifiedDomainName}; Database=${sqlServer::database.name}; User=${appUser}'
output connectionString string = connectionString
output databaseName string = sqlServer::database.name
