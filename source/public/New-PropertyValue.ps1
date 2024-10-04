function New-PropertyValue {
    <#
    .SYNOPSIS
        Creates 1 string from 1 or more values.
    .DESCRIPTION
        The **New-PropertyValue** function combines 1 or more values into 1 string, with or without a "combine character".
    .PARAMETER Object
        Object to get values from.
    .PARAMETER Attributes
        Array of attributes / properties on the object supplies to the Object parameter.
    .PARAMETER CombineCharacter
        Specifies what character, if any, to put between each value.
    .EXAMPLE
        PS C:\> $InputObject = [PSCustomObject]@{
        >>    property1 = "value1"
        >>    property2 = "value2"
        >> }
        PS C:\> $Combine = [PSCustomObject]@{
        >>    attributes = @("property1","property2")
        >>    character = '-'
        >> }
        PS C:\> New-PropertyValue -Object $InputObject -Attributes $Combine.attributes -CombineCharacter $Combine.character
        value1-value2
    .EXAMPLE
        PS C:\> $InputObject = [PSCustomObject]@{
        >>    property1 = "value1"
        >>    property2 = "value2"
        >> }
        PS C:\> $Combine = [PSCustomObject]@{
        >>    attributes = @("property1","property2")
        >>    character = ''
        >> }
        PS C:\> New-PropertyValue -Object $InputObject -Attributes $Combine.attributes -CombineCharacter $Combine.character
        value1value2
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)

        [System.Array](https://learn.microsoft.com/en-us/dotnet/api/system.array)
    .OUTPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/newpropertyvalue/')]
    [OutputType([System.String])]
    param (
        [Parameter()]
        [PSCustomObject]$Object,
        [Parameter()]
        [array]$Attributes,
        [Parameter()]
        [array]$CombineCharacter
    )
    
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    
    process {
        $returnValue = $null
        foreach ($attribute in $Attributes) {
            if ($null -eq $returnValue) {
                $returnValue = "$($Object."$attribute")"
            } else {
                $returnValue = "${returnValue}${CombineCharacter}$($Object."$attribute")"
            }
            Write-CustomLog -Message "returnValue = $returnValue" -Level DEBUG
        }
        if ([String]::IsNullOrEmpty($CombineCharacter)) {

        } else {
            $returnValue = $returnValue.TrimStart($CombineCharacter)
            $returnValue = $returnValue.TrimEnd($CombineCharacter)
        }
        if ([string]::IsNullOrEmpty($returnValue)) {
            Write-CustomLog -Message "returnValue is null" -Level WARN
            return
        } else {
            return $returnValue
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}