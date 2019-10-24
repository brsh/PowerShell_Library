$pathInfo = Microsoft.PowerShell.Management\Get-Location
[bool] $GitFound = $false

if ((-not $pathInfo) -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
    $GitFound = $false
} else {
	[bool] $done = $false
	$curr = Get-Item $PathInfo
	Do {
		$done = $false
		$testing = Test-Path (join-path $curr.FullName '.git')
        if ($testing) {
            $GitFound = $true
            $Done = $true
        } else {
		  $curr = $curr.Parent
        }
        if (-not $curr) { $GitFound = $false; $done = $true }
	} until ($done)
}
$GitFound