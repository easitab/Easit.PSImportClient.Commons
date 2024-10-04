function Add-NewCombineProperty {
    <#
    .SYNOPSIS
        Adds a new calculated property to an existing PSCustomObject.
    .DESCRIPTION
        The **Add-NewCombineProperty** function combines one or more property values into one new property and adds it to the same object.
    .PARAMETER InputObject
        Object to add new proprty to.
    .PARAMETER Combine
        Object with settings for how and what to combine.
    .EXAMPLE
        foreach ($combine in $ConfigurationSourceSettings.combineSourceAttributes.combines) {
            Add-NewCombineProperty -InputObject $returnObject -Combine $combine
        }
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/addnewcombineproperty/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$InputObject,
        [Parameter(Mandatory)]
        [PSCustomObject]$Combine
    )
    
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    
    process {
        try {
            $tempValue = New-PropertyValue -Object $InputObject -Attributes $Combine.attributes -CombineCharacter $Combine.character
        } catch {
            Write-CustomLog -Message "Unable to create new property value" -Level WARN
            Write-CustomLog -InputObject $_ -Level ERROR
            throw
        }
        if (!([string]::IsNullOrEmpty($tempValue))) {
            try {
                Write-CustomLog -Message "Adding property with name $($Combine.combineAttributeOutputName) and value of $tempValue" -Level DEBUG
                $InputObject | Add-Member -MemberType NoteProperty -Name "$($Combine.combineAttributeOutputName)" -Value "$tempValue" -ErrorAction Stop
            } catch {
                Write-CustomLog -Message "Unable to add new property value to object" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        } else {
            Write-CustomLog -Message "New property value is null or empty" -Level WARN
            Write-CustomLog -InputObject $_ -Level ERROR
            return
        }
    }
    
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}