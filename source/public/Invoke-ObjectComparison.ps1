function Invoke-ObjectComparison {
    <#
    .SYNOPSIS
        Invokes an comparison between two sets of objects.
    .DESCRIPTION
        The **Invoke-ObjectComparison** function acts a wrapper to the Compare-Object cmdlet and returnes objects based on what settings have been provided to the *CompareSettings* parameter.

        Basic logic implemented:

        If SideIndicator -eq '=>' and ExcludeDifferent -ne 'true' we add a property called disable with the value of $false and return the object.
        If SideIndicator -eq '==' and IncludeEqual -eq 'true' we add a property called disable with the value of $false and return the object.
        If SideIndicator -eq '<=' we add a property called disable with the value of $true and return the object.
    .PARAMETER ReferenceObject
        Specifies an array of objects used as a reference for comparison.
    .PARAMETER DifferenceObject
        Specifies the objects that are compared to the reference objects.
    .PARAMETER CompareSettings
        Compare settings object from configuration JSON file.
    .EXAMPLE
        $sourceObjects = Invoke-JdbcHandler -SourceDirectory $srcDirectory -ImportClientConfiguration $icConfig -ConfigurationSourceSettings $source
        $referenceObjects = Get-EasitGOItem @getReferenceObjectsParams
        $compareResult += Invoke-ObjectComparison -ReferenceObject $referenceObjects -DifferenceObject $sourceObjects -CompareSettings $source.compare
    .INPUTS
        [System.Collections.ArrayList](https://learn.microsoft.com/en-us/dotnet/api/system.collections.arraylist)

        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/invokeobjectcomparison/')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory,Position=0)]
        [System.Collections.ArrayList]$ReferenceObject,
        [Parameter(Mandatory,Position=1)]
        [System.Collections.ArrayList]$DifferenceObject,
        [Parameter(Mandatory)]
        [PSCustomObject]$CompareSettings
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
        $refDiffCount = 0
        $diffDiffCount = 0
        $equalDiffCount = 0
    }
    process {
        $compareObjectParameters = @{
            ReferenceObject = $ReferenceObject
            DifferenceObject = $DifferenceObject
            PassThru = $true
        }
        if ($CompareSettings.IncludeEqual -eq 'true') {
            $compareObjectParameters.Add('IncludeEqual',$true)
        }
        if ($CompareSettings.ExcludeDifferent -eq 'true') {
            $compareObjectParameters.Add('ExcludeDifferent',$true)
        }
        if ($CompareSettings.properties.Count -gt 0) {
            Write-CustomLog -Message "Running comparison on $($CompareSettings.properties.Count) properties.." -Level DEBUG
            $compareObjectParameters.Add('Property',$CompareSettings.properties)
        } else {
            Write-CustomLog -Message "Running comparison on object level, all properties must match.." -Level DEBUG
        }
        try {
            $compareResult = [System.Collections.ArrayList]@()
            [System.Collections.ArrayList]$compareResult += Compare-Object @compareObjectParameters
        } catch {
            Write-CustomLog -Message "Something went wrong while comparing" -Level WARN
            Write-CustomLog -InputObject $_ -Level ERROR
            throw
        }
        foreach ($compRes in $compareResult) {
            try {
                if ($compRes.SideIndicator -eq '=>') {
                    $diffDiffCount++
                    if ($CompareSettings.ExcludeDifferent -ne 'true') {
                        $compRes | Add-Member -MemberType NoteProperty -Name 'disable' -Value $false -Force
                        $compRes
                    }
                    continue
                }
                if ($compRes.SideIndicator -eq '==') {
                    $equalDiffCount++
                    if ($CompareSettings.IncludeEqual -eq 'true') {
                        $compRes | Add-Member -MemberType NoteProperty -Name 'disable' -Value $false -Force
                        $compRes
                    }
                    continue
                }
                if ($compRes.SideIndicator -eq '<=') {
                    $refDiffCount++
                    $compRes | Add-Member -MemberType NoteProperty -Name 'disable' -Value $true -Force
                    $compRes
                    continue
                }
            } catch {
                Write-CustomLog -Message "Something went wrong while adding property 'disable' before sending" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                continue
            }
        }
        Write-CustomLog -Message "diffDiffCount = $diffDiffCount" -Level DEBUG
        Write-CustomLog -Message "equalDiffCount = $equalDiffCount" -Level DEBUG
        Write-CustomLog -Message "refDiffCount = $refDiffCount" -Level DEBUG
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}