[CmdletBinding(DefaultParameterSetName = 'Computer')]
param (
	[Parameter(Mandatory = $false, ParameterSetName = 'Computer')]
	[string] $Computer = $env:COMPUTERNAME,
	[Parameter(Mandatory = $true, ParameterSetName = 'Domain')]
	[string] $Domain,
	[switch] $Detailed = $false
)

$splat = @{
	$splat.Target = $Computer
	$splat.Scope  = 'Server'
}

if ($PSCmdlet.ParameterSetName -eq 'Domain') {
	$splat.Target = $Domain
	$splat.Scope = 'Domain'
}

Get-ADReplicationPartnerMetadata @splat | Select-Object Server, LastReplicationAttempt, LastReplicationSuccess, ConsecutiveReplicationFailures
