function New-KubernetesCredentialSpec {

  <#
    .SYNOPSIS
    Creates credential spec object for AKS Windows Containers.

    .DESCRIPTION
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]
    $AccountName,

    [Parameter(Mandatory = $false)]
    [string]
    $Domain
  )


  $computerDomain = Get-ADDomain -Current LocalComputer -ErrorAction Continue
  if (!$computerDomain) {
    Write-Error "Could not obtain computer's domain account, please verify your network connectivity and whether computer is domain joined"
    return
  }

  $gmsaAccount = Get-ADServiceAccount $AccountName
  if (!$gmsaAccount) {
    Write-Error "Could not find $AccountName in the domain, please double check the name"
    return
  }

  # Start hash table for output
  $credSpec = [ordered]@{
    apiVersion = "windows.k8s.io/v1alpha1"
    kind       = "GMSACredentialSpec"
    metadata   = @{
      name = "$($computerDomain.NetBIOSName)-${AccountName}"  #This is an arbitrary name but it will be used as a reference
    }
    credspec   = [ordered]@{
      ActiveDirectoryConfig = @{
        GroupManagedServiceAccounts = @(
          [ordered]@{
            Name  = $AccountName   #Username of the GMSA account
            Scope = $computerDomain.DNSRoot  #NETBIOS Domain Name
          },
          [ordered]@{
            Name  = $AccountName   #Username of the GMSA account
            Scope = $computerDomain.NetBIOSName #DNS Domain Name
          }
        )
      }
      CmsPlugins            = @(
        "ActiveDirectory"
      )
      DomainJoinConfig      = [ordered]@{
        DnsName            = $computerDomain.DNSRoot  #DNS Domain Name
        DnsTreeName        = $computerDomain.Forest #DNS Domain Name Root
        Guid               = $computerDomain.ObjectGUID  #GUID
        MachineAccountName = $AccountName #Username of the GMSA account
        NetBiosName        = $computerDomain.NetBIOSName  #NETBIOS Domain Name
        Sid                = $gmsaAccount.SID #SID of GMSA
      }
    }
  }

  $credSpec
}
