[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]$Name,
    [Parameter(Mandatory)]
    [String[]]$Tags = @('function','public'),
    [Parameter()]
    [String]$GetSourceDataFrom
)

begin {
    
}

process {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    if ($Tags -contains 'private') {
        $functionVisibility = 'private'
    } else {
        $functionVisibility = 'public'
    }
    $sourceDirectory = Join-Path -Path $projectRoot -ChildPath 'source' -AdditionalChildPath $functionVisibility
    $testFunctionDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'function'
    $testTemplate = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'pesterTestTemplate.ps1') -Raw
    $testFileName = "${Name}.Tests.ps1"
    $sourceFileName = "${Name}.ps1"
    if ($null -eq $testTemplate -or $testTemplate.Length -lt 1) {
        throw "Test template is null or empty"
    }
    if ($Tags.Count -gt 0) {
        foreach ($tag in $Tags) {
            $tagsString = [String]::Format("{0}'{1}',",$tagsString,$tag)
        }
        $tagsString = $tagsString.Remove(($tagsString.Length - 1),1)
        $testTemplate = $testTemplate.Replace('--tags--',"-Tag $tagsString")
    } else {
        $testTemplate = $testTemplate.Replace('--tags-- ','')
    }
    $testTemplate = $testTemplate.Replace('--FunctionName--',$Name)
    $testTemplate | Out-File -FilePath (Join-Path -Path $testFunctionDirectory -ChildPath $testFileName) -Encoding utf8 -Force
    if (![String]::IsNullOrEmpty($GetSourceDataFrom)) {
        if (Test-Path -Path $GetSourceDataFrom) {
            $sourceData = Get-Content -Path $GetSourceDataFrom -Raw
            $regexp = "function $Name \{.+\}"
            $sourceData = $sourceData -match "$regexp"
        } else {
            Write-Warning "Unable to find $GetSourceDataFrom"
        }
    } else {
        $null = New-Item -Path $sourceDirectory -Name $sourceFileName -ItemType File
    }
}

end {
    
}