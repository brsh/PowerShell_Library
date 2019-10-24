import-module WebAdministration

function Get-LogConfig {
    dir iis:\sites | foreach-Object {
        $loggingFilter = "/system.applicationHost/sites/site[@name=`"$($_.Name)`"]/LogFile"
        "For $($_.Name)"
        Get-WebConfigurationProperty -filter $loggingFilter -Name LogExtFileFlags
    }
}


"Current Config:"
Get-LogConfig

$NewOptions = "Date,Time,SiteName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Host,HttpSubStatus"
dir iis:\sites | foreach-Object {
    $loggingFilter = "/system.applicationHost/sites/site[@name=`"$($_.Name)`"]/LogFile"
    "... Setting: $($_.Name)"
    Set-WebConfigurationProperty -filter $loggingFilter -Name LogExtFileFlags -Value $NewOptions
}

""
"And Now...:"
Get-LogConfig