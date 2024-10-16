function Update-Archive {
    <#
    .SYNOPSIS
        Updates the PSImportClient archive directory.
    .DESCRIPTION
        The **Update-Archive** function updates, meaning adding and removing, the PSImportClient archive directory where any files with source object is moved to after an import from it was successfull.

        The **Update-Archive** function attempts to update the archive by doing things in the following order.

        1. Copy file with source object(s) from original location to the directory specified in the settings file.
        2. Remove file from its original location.
        3. Remove files in the archive directory older than specified in the settings file.
    .PARAMETER ArchiveSettings
        Object with settings for the archive.
    .PARAMETER FileToArchive
        Full path for file to archive.
    .PARAMETER ConfigurationName
        Name of configuration that is invoking the archiving.
    .PARAMETER SourceName
        Name of source that is invoking the archiving.
    .PARAMETER AddToArchive
        Specifies if file should be added to archive.
    .PARAMETER RotateArchive
        Specifies if archive should be rotated.
    .EXAMPLE
        $archiveUpdate = @{
            AddToArchive = $true
            ArchiveSettings = $psImportClientSettings.archiveSettings
            ConfigurationName = "$($destination.Name)"
            FileToArchive = (Join-Path -Path $icConfig.sourceSettingsObject.path -ChildPath $icConfig.sourceSettingsObject.fileNameWithExtension)
            SourceName = $source.name
        }
        Update-Archive @archiveUpdate
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)

        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/updatearchive/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$ArchiveSettings,
        [Parameter()]
        [string]$FileToArchive,
        [Parameter()]
        [string]$ConfigurationName,
        [Parameter()]
        [string]$SourceName,
        [Parameter()]
        [switch]$AddToArchive,
        [Parameter()]
        [switch]$RotateArchive
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        if ($AddToArchive) {
            try {
                Write-CustomLog -Message "Testing archive settings" -Level DEBUG
                Test-ArchiveSettings -Settings $ArchiveSettings
            } catch {
                Write-CustomLog -Message "Failed while testing archive settings" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
            try {
                Write-CustomLog -Message "Adding file to archive" -Level DEBUG
                Add-FileToArchive -FileToArchive $FileToArchive -ArchiveDirectory $ArchiveSettings.directory -ConfigurationName $ConfigurationName -SourceName $SourceName
            } catch {
                Write-CustomLog -Message "Failed to add file to archive" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
            try {
                Write-CustomLog -Message "Removing source file" -Level DEBUG
                Remove-Item -Path $FileToArchive -Force -Confirm:$false -ErrorAction Stop
            } catch {
                Write-CustomLog -Message "Failed to remove source file" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
        if ($RotateArchive) {
            try {
                Write-CustomLog -Message "Rotating archive" -Level DEBUG
                Set-Archive -ArchiveSettings $ArchiveSettings
            } catch {
                Write-CustomLog -Message "Failed to rotate archive" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}