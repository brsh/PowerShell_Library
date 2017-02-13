	if($BuildVersion.Major -eq '6' -and $BuildVersion.Minor -le '1') {
		# RegIIS is unnecessary on 2012 and above
		if (Test-Path 'C:\Windows\Microsoft.NET\Framework64\') {
			"Registering .Net Framework 4.5+ with IIS"
			$regiis='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe'
			$reval = Start-Process $regiis -ArgumentList '-i' -wait -NoNewWindow -PassThru
			"RegIIS Response code was: $retval.ExitCode"
		}
	}