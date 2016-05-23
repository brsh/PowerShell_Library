<# 
.SYNOPSIS 
    Unzip file and rename the extracted files 

.DESCRIPTION 
    This is a specialized unzipping routine. It expects a non-empty zip file. It will extract the file, renaming the contents to a new name based on the zip filename adding a timestamp.

    So, if the zip file, called test.zip, contains hello.txt and we run this script at 8:02:26am on June 1, 2034, then the extracted file will be:

        test-20340601080226.txt

    The "test" part comes from the original zip file

    The "20340601080226" part comes from the time

    The "txt" part comes from the extracted files original file extention

.PARAMETER  File
    The Zip File to extract. This must be a "real" path and filename, without using PSDrives

.PARAMETER  Detination
    The location for the extracted files

.EXAMPLE 
    PS C:\> .\Expand-and-Rename-ZipFile -file .\TEST.zip -destination c:\Files

.EXAMPLE 
    PS C:\> get-childitem *.zip | .\Expand-and-Rename-ZipFile -destination c:\Files

#> 


param ( 
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)] 
    [ValidateScript({ 
        If ((Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.zip")) { 
            $true 
        } 
        else { 
            Throw "$_ is not a valid zip file. Enter in 'c:\folder\file.zip' format" 
        } 
    })] 
    [string]$ZipFile, 
    [ValidateNotNullOrEmpty()] 
    [ValidateScript({ 
        If (Test-Path -Path $_ -PathType Container) { 
            $true 
        } 
        else { 
            Throw "$_ is not a valid destination folder. Enter in 'c:\destination' format" 
        } 
    })] 
    [Parameter(Position=1, Mandatory=$true)]
    [string]$Destination = (Get-Location).Path
)

BEGIN { }

PROCESS {
    ForEach ($FileObject in $ZipFile) {
        #The COM Object doesn't like . for current directory
        $file = (Resolve-Path $FileObject).Path.ToString()
        $Destination = (Resolve-Path $Destination).Path.ToString()
        
        Write-Verbose -Message "Attempting to Unzip $File to location $Destination" 
        
        #This script uses the Shell.Application COM Object to work with Zip files
        #It's limited (example: no rename method... at all) - but it works
        #We also load the FileInfo object for easier renaming
        $ShellAppObject = new-object -com shell.application
        
        $ZipFileSource = Get-ChildItem $File
        $ZipFileObject = $ShellAppObject.namespace($File)
        $DestinationObject = $ShellAppObject.namespace($Destination)
        
        #Now, pull out the zipped items
        $retval = $ZipFileObject.Items()
        
        #And process thru them 1 at a time
        if ($retval) {
            $retval | ForEach-Object {
                #Process only if this is not a folder - ie., is a file)
                if (-not ($_.isFolder)) {
                    "`nExtracting {0} to {1}" -f $_.Name, $Destination
                    $DestinationObject.CopyHere($_, 0x14)
                    
                    #The filename of the extracted file = directory + filename
                    #Load the FileInfo object for easier renaming
                    $oldname = $Destination
                    $oldname += "\"
                    $oldname += $_.Name
                    $ExtractedFileObject = Get-ChildItem $oldname
            
                    #Set things up for our loop
                    #Will stop if it's successful or if it errors 10 times
                    $Successful = $false
                    $RunThru = 1
            
                    Do {
                        #The new name = Base name of the zip file + long data + current extension
                        $newname = $ZipFileSource.BaseName
                        $newname += "-"
                        $newname += (get-date).ToString("yyyyMMddhhmmss")
                        $newname += $ExtractedFileObject.Extension
                        
                        #Here's the renaming magic
                        #Will try to rename the file, failing if one already exists
                        #Marking Success if ... um... sucessful
                        Try {
                            "Attempt #{0}: Renaming {1} to {2}" -f $RunThru, $oldname, $newname
                            $ExtractedFileObject | Rename-Item -NewName { $_.BaseName.Replace($_.Basename, $newname) } -ea Stop
                            $Successful = $true
                        }
                        catch { 
                            #But, if errored, then sleep a second and try again
                            #Catches filename confilicts since we're using timestamps
                            "Error renaming the file: {0}" -f $_.Exception.Message
                            $successful = $false
                            $RunThru ++
                            if ($runthru -gt 10) { 
                                $Successful = $true 
                            }
                            else { start-sleep 1 } 
                        }
                    }
                    While (-not ($Successful)) # Endf the Do loop
                }
            }
        }
        else {
            "Error: Source zip did not return any files"
        }
    }

}

END {}