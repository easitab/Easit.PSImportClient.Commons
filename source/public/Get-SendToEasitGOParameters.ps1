function Get-SendToEasitGOParameters {
    <#
    .SYNOPSIS
        Get parameters for *Get-SendToEasit* as hashtable.
    .DESCRIPTION
        The **Get-SendToEasitGOParameters** creates a hashtable for the parameters to be used with *Send-ToEasitGO*.

        When settings from the configuration file is imported and converted from JSON we get a PSCustomObject back. To be able to use splatting we need to convert that object to a hashtable.
    .PARAMETER SourceSettings
        Object with settings for source.
    .PARAMETER DestinationSettings
        Object with settings for destination.
    .EXAMPLE
        $sendToEasitGOParams = Get-SendToEasitGOParameters -SourceSettings $source -DestinationSettings $destination
        Send-ToEasitGO @sendToEasitGOParams -Item $objectsToSend
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        [Hashtable](https://learn.microsoft.com/en-us/dotnet/api/system.collections.hashtable)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/getsendtoeasitgoparameters/')]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$SourceSettings,
        [Parameter(Mandatory)]
        [PSCustomObject]$DestinationSettings
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        $sendToEasitGOParams = @{
            Url = $DestinationSettings.url
            Apikey = $DestinationSettings.apiKey
        }
        if ($null -eq $SourceSettings.importHandlerIdentifier -or [String]::IsNullOrEmpty($SourceSettings.importHandlerIdentifier)) {
            $sendToEasitGOParams.Add('ImportHandlerIdentifier',$DestinationSettings.importHandlerIdentifier)
        } else {
            $sendToEasitGOParams.Add('ImportHandlerIdentifier',$SourceSettings.importHandlerIdentifier)
        }
        if (($SourceSettings.batchSize -ge 1 -and $SourceSettings.batchSize -lt 50) -or $SourceSettings.batchSize -gt 50) {
            $sendToEasitGOParams.Add('SendInBatchesOf',$SourceSettings.batchSize)
        }
        if ($SourceSettings.batchDelay -gt 0) {
            $sendToEasitGOParams.Add('DelayBetweenBatches',$SourceSettings.batchDelay)
        }
        if ($DestinationSettings.InvokeRestMethodParameters) {
            try {
                $tempHash = Convert-PsObjectToHashtable -InputObject $DestinationSettings.invokeRestMethodParameters
                $sendToEasitGOParams.Add('InvokeRestMethodParameters',$tempHash)
            } catch {
                Write-CustomLog -Message "Failed to convert invokeRestMethodParameters to hashtable" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
        if ($SourceSettings.writeXML) {
            $sendToEasitGOParams.Add('WriteBody',$true)
        }
        if ($SourceSettings.dryRun) {
            $sendToEasitGOParams.Add('DryRun',$true)
        }
        return $sendToEasitGOParams
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}