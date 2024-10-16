function Add-FileToArchive {
    <#
    .SYNOPSIS
        Adds an file to the archive.
    .DESCRIPTION
        The **Add-FileToArchive** function adds a file to the archive by copying it from its original location.

        Its new location is a combination of the destination name, source name, date and a new name in the combination of the time and original file name.

        Ex: archive/test/jdbcSource/date/time_filename.fileextension
    .PARAMETER ArchiveDirectory
        Path to archive.
    .PARAMETER FileToArchive
        Path to file to archive.
    .PARAMETER ConfigurationName
        Name of destination configuration.
    .PARAMETER SourceName
        Name of source configuration.
    .EXAMPLE
        $addFileToArchiveParams = @{
            FileToArchive = $FileToArchive
            ArchiveDirectory = $ArchiveSettings.directory
            ConfigurationName = $ConfigurationName
            SourceName = $SourceName
        }
        Add-FileToArchive @addFileToArchiveParams
    .INPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/addfiletoarchive/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [string]$ArchiveDirectory,
        [Parameter(Mandatory)]
        [string]$FileToArchive,
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$SourceName
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        if (Test-Path -Path $FileToArchive) {
            $nowDate = Get-Date -Format "yyyy-MM-dd"
            $nowTime = Get-Date -Format "HHmmss"
            $fileObject = Get-ChildItem -Path $FileToArchive
            $fileName = "$($fileObject.Name)"
            $configurationArchiveDirectory = Join-Path -Path $ArchiveDirectory -ChildPath "$ConfigurationName"
            if (!(Test-Path -Path $configurationArchiveDirectory)) {
                $configurationArchiveDirectory = New-Item -Path $ArchiveDirectory -Name "$ConfigurationName" -ItemType Directory
            }
            $sourceArchiveDirectory = Join-Path -Path $configurationArchiveDirectory -ChildPath "$SourceName"
            if (!(Test-Path -Path $sourceArchiveDirectory)) {
                $sourceArchiveDirectory = New-Item -Path $configurationArchiveDirectory -Name "$SourceName" -ItemType Directory
            }
            $dateSourceArchiveDirectory = Join-Path -Path $sourceArchiveDirectory -ChildPath "$nowDate"
            if (!(Test-Path -Path $dateSourceArchiveDirectory)) {
                $dateSourceArchiveDirectory = New-Item -Path $sourceArchiveDirectory -Name $nowDate -ItemType Directory
            }
            $destinationFile = Join-Path -Path $dateSourceArchiveDirectory -ChildPath "${nowTime}_${fileName}"
            try {
                Copy-Item -Path $fileObject.FullName -Destination $destinationFile
            } catch {
                throw
            }
        } else {
            throw "Unable to find $FileToArchive"
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}