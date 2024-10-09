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
        if ([String]::IsNullOrEmpty($Prefix)) {
            $Prefix = '*'
        }
        if ([String]::IsNullOrEmpty($Suffix)) {
            $Suffix = '*'
        }
        try {
            Get-ChildItem -Path $Path -Recurse -Include "${Prefix}.${Suffix}" -File
        } catch {
            throw
        }
    }
    
    end {
        
    }
}