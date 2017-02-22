## Get SysInternals utilities

function Expand-ZIPFile($file) {
    try { 
        " Extracting $file"
        [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null 
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$File", "$script:WorkPath")
        del "$script:WorkPath\Eula.txt"
        try {
            "  Deleting $file"
            del $file
        }
        catch { "    -- Unexpected Error."; "    -- $_.Exception.Message" }
    } 
    catch { "    -- Unexpected Error.";"    -- $_.Exception.Message" }
}

# Current script path
[string]$ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
[string]$WorkPath = "$ScriptPath\SysInternals"

if (Test-Path $WorkPath) {
    "SysInternals folder already exists. Deleting files..."
    del "$WorkPath\*.*"
} else {
    mkdir $WorkPath
}

$Files = @()

$Files += "AccessChk.zip"
$Files += "AccessEnum.zip"
$files += "AdExplorer.zip"
$files += "AdInsight.zip"
$files += "Autoruns.zip"
$files += "Disk2vhd.zip"
$files += "DU.zip"
$files += "Handle.zip"
$files += "logonSessions.zip"
$files += "PendMoves.zip"
$files += "ProcessExplorer.zip"
$files += "ProcessMonitor.zip"
$files += "PSTools.zip"
$files += "SDelete.zip"
$files += "ShareEnum.zip"
$files += "Streams.zip"
$files += "Sync.zip"
$files += "Sysmon.zip"
$files += "WhoIs.zip"
$files += "ZoomIt.zip"

foreach ($file in $Files) {
    "Downloading $file ..."
    Try {
        (New-Object Net.WebClient).DownloadFile("https://download.sysinternals.com/files/$file", "$WorkPath\$file")
        Expand-ZIPFile "$WorkPath\$file"
    }
    Catch { "    -- Error getting $file. Check that they haven't changed the name, verify caps, etc...."; "    -- $_.Exception.Message" }
}

