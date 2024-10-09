function Test-HelpSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$CommandName
    )
    
    begin {
        
    }
    
    process {
        try {
            $helpObject = Get-Help -Name "$CommandName" -Full -ErrorAction Stop
        } catch {
            throw
        }
        $helpSections = @('SYNOPSIS','DESCRIPTION','EXAMPLES','inputTypes','returnValues')
        foreach ($helpSection in $helpSections) {
            if ($helpObject."$helpSection".Length -lt 1) {
                throw "$CommandName is missing a $helpSection"
            }
        }
        $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
        $optionalCommonParameters = [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        foreach ($param in $helpObject.parameters.parameter) {
            if ($commonParameters -notcontains $param.name -and $optionalCommonParameters -notcontains $param.name) {
                if ($param.description.Text.Length -lt 1) {
                    throw "Parameter $($param.name) does not have a description"
                }
            }
        }
        try {
            $commandObject = Get-Command -Name "$CommandName" -ErrorAction Stop
        } catch {
            throw
        }
        $commandSections = @('HelpUri')
        foreach ($commandSection in $commandSections) {
            if ($commandObject."$commandSection".Length -lt 1) {
                throw "$CommandName is missing a $commandSection"
            }
        }
    }
    
    end {
        
    }
}