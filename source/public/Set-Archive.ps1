function Set-Archive {
    <#
    .SYNOPSIS
        Sets the archive according to settings.
    .DESCRIPTION
        The **Set-Archive** function removes any old files and empty directories from the archive.
    .PARAMETER ArchiveSettings
        Object with settings for the archive.
    .EXAMPLE
        Set-Archive -ArchiveSettings $ArchiveSettings
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/setarchive/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$ArchiveSettings
    )
    
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    
    process {
        $ArchiveRotationInterval = $ArchiveSettings.rotationInterval
        $archiveEndOfLife = (Get-Date).AddDays("-${ArchiveRotationInterval}").Date
        try {
            $archiveFiles = Get-ChildItem -Path $ArchiveSettings.directory -Recurse -File
        } catch {
            Write-CustomLog -Message "$($_.Exception.Message)" -Level WARN
        }
        if ($archiveFiles) {
            Write-CustomLog -Message "Removing old archive files" -Level VERBOSE
            foreach ($archiveFile in $archiveFiles) {
                if ($archiveFile.CreationTime.Date -lt $archiveEndOfLife) {
                    try {
                        Remove-Item $archiveFile -Force -Confirm:$false
                    } catch {
                        Write-CustomLog -Message "$($_.Exception.Message)" -Level WARN
                        continue
                    }
                }
            }
        }
        $emptyDirectories = Get-ChildItem -Path $ArchiveSettings.directory -Recurse -Directory | Where-Object {$_.GetFileSystemInfos().Count -eq 0} | Select-Object FullName
        if ($emptyDirectories) {
            Write-CustomLog -InputObject "Removing empty archive directories" -Level VERBOSE
            foreach ($emptyDirectory in $emptyDirectories) {
                try {
                    Remove-Item "$($emptyDirectory.FullName)" -Force -Confirm:$false
                } catch {
                    Write-CustomLog -Message "$($_.Exception.Message)" -Level WARN
                    continue
                }
            }
        }
    }
    
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}