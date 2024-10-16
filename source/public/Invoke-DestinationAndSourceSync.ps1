function Invoke-DestinationAndSourceSync {
    <#
    .SYNOPSIS
        Updates source settings with destination settings values.
    .DESCRIPTION
        The **Invoke-DestinationAndSourceSync** sets some values from the destination settings object on the source settings object if they are missing or null. This function makes so that you can override some settings for each source. Ex. if the source does not have a URL, the URL from the destination is used.

        Properties that this function "synchronizes" are:

        * url
        * apiKey
        * writeXML
        * dryRun
        * batchSize
        * batchDelay
    .PARAMETER Destination
        Destination settings object.
    .PARAMETER Source
        Source settings object.
    .EXAMPLE
        PS C:\> $Destination = [PSCustomObject]@{
        >>    URL = "value1"
        >>    apiKey = "value2"
        >>    writeXML = "value3"
        >> }
        PS C:\> $Source = [PSCustomObject]@{
        >>    URL = "value4"
        >>    apiKey = "value5"
        >> }
        PS C:\> Invoke-DestinationAndSourceSync -Destination $Destination -Source $Source
        PS C:\> $Source

        URL    apiKey writeXML
        ---    ------ --------
        value4 value5 value3
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/invokedestinationandsourcesync/')]
    [OutputType()]
    param (
        [Parameter()]
        [PSCustomObject]$Destination,
        [Parameter()]
        [PSCustomObject]$Source
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        if (($null -eq $destination.url -or [String]::IsNullOrEmpty($destination.url)) -and ($null -eq $source.url -or [String]::IsNullOrEmpty($source.url))) {
            Write-CustomLog -Message "url for both destination and source is null" -Level ERROR
            throw
        }
        if (($null -eq $destination.apiKey -or [String]::IsNullOrEmpty($destination.apiKey)) -and ($null -eq $source.apiKey -or [String]::IsNullOrEmpty($source.apiKey))) {
            Write-CustomLog -Message "apiKey for both destination and source is null" -Level ERROR
            throw
        }
        if ([String]::IsNullOrEmpty($source.icConfigurationIdentifier)) {
            Write-CustomLog -Message "source.icConfigurationIdentifier is null or empty" -Level ERROR
            throw
        }
        if ([String]::IsNullOrEmpty($source.url)) {
            try {
                $source | Add-Member -MemberType NoteProperty -Name 'url' -Value $destination.url -Force
            } catch {
                Write-CustomLog -Message "Failed to add url from destination settings to source settings" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
        if ([String]::IsNullOrEmpty($source.apiKey)) {
            try {
                $source | Add-Member -MemberType NoteProperty -Name 'apiKey' -Value $destination.apiKey -Force
            } catch {
                Write-CustomLog -Message "Failed to add apiKey from destination settings to source settings" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
        if ([String]::IsNullOrEmpty("$($source.writeXML)")) {
            if ([String]::IsNullOrEmpty("$($destination.writeXML)")) {

            } else {
                try {
                    $source | Add-Member -MemberType NoteProperty -Name 'writeXML' -Value $destination.writeXML -Force
                } catch {
                    Write-CustomLog -Message "Failed to add writeXML from destination settings to source settings" -Level WARN
                    Write-CustomLog -InputObject $_ -Level ERROR
                    throw
                }
            }
        }
        if ([String]::IsNullOrEmpty("$($source.dryRun)")) {
            if ([String]::IsNullOrEmpty("$($destination.dryRun)")) {

            } else {
                try {
                    $source | Add-Member -MemberType NoteProperty -Name 'dryRun' -Value $destination.dryRun -Force
                } catch {
                    Write-CustomLog -Message "Failed to add dryRun from destination settings to source settings" -Level WARN
                    Write-CustomLog -InputObject $_ -Level ERROR
                    throw
                }
            }
        }
        if ([String]::IsNullOrEmpty("$($source.batchSize)")) {
            if ([String]::IsNullOrEmpty("$($destination.batchSize)")) {

            } else {
                try {
                    $source | Add-Member -MemberType NoteProperty -Name 'batchSize' -Value $destination.batchSize -Force
                } catch {
                    Write-CustomLog -Message "Failed to add batchSize from destination settings to source settings" -Level WARN
                    Write-CustomLog -InputObject $_ -Level ERROR
                    throw
                }
            }
        }
        if ([String]::IsNullOrEmpty("$($source.batchDelay)")) {
            if ([String]::IsNullOrEmpty("$($destination.batchDelay)")) {

            } else {
                try {
                    $source | Add-Member -MemberType NoteProperty -Name 'batchDelay' -Value $destination.batchDelay -Force
                } catch {
                    Write-CustomLog -Message "Failed to add batchDelay from destination settings to source settings" -Level WARN
                    Write-CustomLog -InputObject $_ -Level ERROR
                    throw
                }
            }
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}