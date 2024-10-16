function Test-ArchiveSettings {
    <#
    .SYNOPSIS
        Tests the archive settings.
    .DESCRIPTION
        The **Test-ArchiveSettings** function checks that if the 'directory' key is null, we use a default value.
    .PARAMETER Settings
        Object with settings for the archive.
    .EXAMPLE
        Test-ArchiveSettings -Settings $ArchiveSettings
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/testarchivesettings/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$Settings
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        foreach ($setting in $Settings.psobject.properties.GetEnumerator()) {
            if ($setting.value.GetType().Name -ne 'String') {
                continue
            }
            if ([string]::IsNullOrEmpty("$($setting.value)")) {
                if ("$($setting.name)" -eq 'directory') {
                    $Settings.directory = 'archive'
                }
                Write-CustomLog -Message "$($setting.name) setting was null or empty, using default value ($Settings."$($setting.name)")" -Level WARN
            }
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}