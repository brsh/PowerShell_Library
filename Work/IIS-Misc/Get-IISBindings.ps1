
Import-Module WebAdministration
$env:computername | out-file "$env:userprofile\Documents\$env:computername.txt"
ipconfig | Where-Object { $_ -match "IPv4" } | ForEach-Object { $_.split(":")[1].Trim() } | out-file "$env:userprofile\Documents\$env:computername.txt" -append
cd iis:\sites 
"" | out-file "$env:userprofile\Documents\$env:computername.txt" -append
Get-ChildItem | ForEach-Object { 
	$_.Name; 
	"  $($_.PhysicalPath)"; 
	"  $($_.State)";
	$_.Bindings.Collection | foreach-object { "  $($_.Protocol) - $($_.BindingInformation)" }
	""
} | out-file "$env:userprofile\Documents\$env:computername.txt" -append



