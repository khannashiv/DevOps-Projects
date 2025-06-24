param location string = 'centralindia'
param gatewayName string = 'my-app-gw'

@description('Reference to existing VNet')
param vnetName string
param vnetResourceGroup string

@description('Reference to existing Public IP')
param publicIpName string
param publicIpResourceGroup string

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: 'appgw-subnet'
  parent: vnet
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' existing = {
  name: publicIpName
  scope: resourceGroup(publicIpResourceGroup)
}

resource appGw 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: gatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: appgwSubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGwFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'my-backend-pool'
        properties: {
          backendAddresses: [
            { ipAddress: '10.0.0.4' }
            { ipAddress: '10.0.0.5' }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'my-http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'my-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', gatewayName, 'appGwFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', gatewayName, 'appGwFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'my-routing-rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', gatewayName, 'my-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', gatewayName, 'my-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', gatewayName, 'my-http-settings')
          }
          priority: 100
        }
      }
    ]
  }
}
