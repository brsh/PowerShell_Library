$Escape = "$([char]27)"
$AnsiColor = $null

$FColor = @{
	Black       = "$Escape[0;30m"
	Gray        = "$Escape[0;37m"
	Blue        = "$Escape[1;34m"
	Green       = "$Escape[1;32m"
	Cyan        = "$Escape[1;36m"
	Red         = "$Escape[1;91m"
	Magenta     = "$Escape[1;35m"
	Yellow      = "$Escape[1;33m"
	White       = "$Escape[1;37m"
	DarkBlue    = "$Escape[0;34m"
	DarkCyan    = "$Escape[0;36m"
	DarkGray    = "$Escape[1;30m"
	DarkGreen   = "$Escape[0;32m"
	DarkMagenta = "$Escape[0;35m"
	DarkRed     = "$Escape[0;31m"
	DarkYellow  = "$Escape[0;33m"
	Off         = "$Escape[0m"
}

$BColor = @{
	DarkBlue    = "$Escape[44m"
	DarkGreen   = "$Escape[42m"
	DarkCyan    = "$Escape[46m"
	DarkRed     = "$Escape[41m"
	DarkMagenta = "$Escape[45m"
	DarkYellow  = "$Escape[43m"
	DarkGray    = "$Escape[0;100"
	Black       = "$Escape[40m"
	Gray        = "$Escape[47m"
	Blue        = "$Escape[0;104m"
	Green       = "$Escape[0;102m"
	Cyan        = "$Escape[0;106m"
	Red         = "$Escape[0;101m"
	Magenta     = "$Escape[0;105m"
	Yellow      = "$Escape[0;103m"
	White       = "$Escape[0;107m"
}

function Get-ColorsAnsi {
	$FColor.GetEnumerator() | ForEach-Object {
		$color = $_
		write-host " $($Color.Key.ToString().PadRight(12)) " -NoNewline
		$BColor.GetEnumerator() | ForEach-Object {
			write-host " $($color.Value)$($_.Value)$($_.Key.PadRight(5))$off " -NoNewline
		}
		write-host ''
	}
}
