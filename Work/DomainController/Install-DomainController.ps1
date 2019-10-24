<#
.SYNOPSIS
Install a child domain controller

.DESCRIPTION
This script will attempt to install a domain controller using base information specified on the command line.

This is not intended to install a new domain, just a child DC.

.PARAMETER DomainName
The FQDN of the domain this will be a DC for

.PARAMETER DirectoryRecoveryPassword
The password to use as the Directory Recovery Password

.PARAMETER IsReadOnly
This DC will be a Read-Only DC

.EXAMPLE
Install-DomainController.ps1 -DomainName 'my.domain.local' -DirectoryRecoveryPassword 'SomeBizarelyLongPassword'

#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
	[Alias('Name', 'FQDN', 'Domain')]
	[string] $DomainName = $env:USERDNSDOMAIN,
	[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias('Password', 'Key', 'Secret')]
	[string] $DirectoryRecoveryPassword,
	[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
	[Alias('ReadOnly', 'RO')]
	[bool] $IsReadOnly = $false
)

"Testing for AD Domain Services"
Try {
	if ((Get-WindowsFeature -Name 'AD-Domain-Services').Installed) {
		"  AD Features already installed"
	} else {
		Install-WindowsFeature -Name 'AD-Domain-Services' -IncludeManagementTools
	}
} catch {
	$_
	Throw "Could not install AD-Domain-Services"
	exit
}

"Testing for AD Tools"
Try {
	if ((Get-WindowsFeature -Name RSAT-AD-Tools).Installed) {
		"  AD Management tools already installed"
	} else {
		Install-WindowsFeature -Name 'RSAT-AD-Tools' -IncludeAllSubFeature
	}
} catch {
	$_
	Throw "Could not install RSAT-AD-Tools"
	exit
}

"Testing if this is already a domain controller"
try {
	$DCInfo = Get-ADDomainController -Identity $env:COMPUTERNAME -ErrorAction Stop
	"  This server is already a Domain Controller: "
	"    $DCInfo.ComputerObjectDN"
	Throw "Can not install domain services on an existing Domain Controller"
	exit
} catch {
	"  This system is not already a domain controller. Continuing..."
}

$dirpass = ConvertTo-SecureString $DirectoryRecoveryPassword -AsPlainText -Force
$LogFile = "C:\${DomainName}-dcpromo.log"

$DSHash = @{
	SafeModeAdministratorPassword = $dirpass
	DomainName                    = $DomainName
	Force                         = $true
	LogPath                       = $LogFile
}

"Installing the DC. See the log information in ${LogFile}"

if ($IsReadOnly) {
	"  Read-Only DC requested... checking Site Name"
	[string] $SiteName = $(nltest /dsgetsite 2>$null).split("`n")[0]
	if ($SiteName.Length -lt 1) {
		"    Read-only DCs require a sitename"
		throw "Could not find site name"
		exit
	}
	"    Site name found: ${SiteName}"
	$DSHash.SiteName = $SiteName
	$DSHash.ReadOnlyReplica = $true
}

try {
	Import-Module -Name 'ActiveDirectory' -ErrorAction Stop -Verbose:$false
	Install-ADDSDomainController @DSHash
} catch {
	"Could not install a domain controller..."
	$_
}


