function Get-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter()]
        [string]$Prefix,
        [Parameter()]
        [string]$Suffix
    )
    
    begin {
        
    }
    
    process {
        if ([String]::IsNullOrEmpty($Path)) {
            throw "Path is null or empty"
        }
        $getCIparams = @{
            Recurse = $true
            File = $true
        }
        if ([String]::IsNullOrEmpty($Prefix) -and [String]::IsNullOrEmpty($Suffix)) {
            try {
                Get-ChildItem -Path "$Path\*" @getCIparams
            } catch {
                throw
            }
        } else {
            if ([String]::IsNullOrEmpty($Prefix)) {
                $Prefix = '*'
            }
            if ([String]::IsNullOrEmpty($Suffix)) {
                $Suffix = '*'
            }
            try {
                Get-ChildItem -Path $Path @getCIparams -Include "${Prefix}.${Suffix}"
            } catch {
                throw
            }
        }
    }
    
    end {
        
    }
}