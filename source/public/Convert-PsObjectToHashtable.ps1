function Convert-PsObjectToHashtable {
    <#
    .SYNOPSIS
        Creates a hashtable from the properties of an object.
    .DESCRIPTION
        The **Convert-PsObjectToHashtable** iterates of an objects properties, adds them to a hashtable and returns the hashtable.
        
        The property name is the key and the property value its value.
    .PARAMETER InputObject
        Object to convert.
    .EXAMPLE
        $tempHash = Convert-PsObjectToHashtable -InputObject $invokeRestMethodParametersFromSettingsFile
        $sendToEasitGOParams.Add('InvokeRestMethodParameters',$tempHash)
        Send-ToEasitGO @sendToEasitGOParams
    .INPUTS
        [System.Object](https://learn.microsoft.com/en-us/dotnet/api/system.object)
    .OUTPUTS
        [Hashtable](https://learn.microsoft.com/en-us/dotnet/api/system.collections.hashtable)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/convertpsobjecttohashtable/')]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [Object]$InputObject
    )
    
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    
    process {
        $tempHash = @{}
        foreach ($prop in $InputObject.psobject.properties) {
            try {
                $tempHash.Add($prop.Name,$prop.Value)
            } catch {
                Write-CustomLog -InputObject $_ -Level WARN
            }
        }
        return $tempHash
    }
    
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}