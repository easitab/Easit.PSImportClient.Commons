BeforeAll {
    $helpersDirectory = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSCommandPath -Parent) -Parent) -ChildPath 'helpers'
    foreach ($helper in (Get-ChildItem -Path $helpersDirectory -Recurse -Include '*.ps1')) {
        . $helper.FullName
    }
    try {
        $envSettings = Get-EnvironmentSetting -Path $PSCommandPath
    } catch {
        throw $_
    }
    if (Test-Path $envSettings.CodeFilePath) {
        . $envSettings.CodeFilePath
    } else {
        Write-Output "Unable to locate code file ($($envSettings.CodeFilePath)) to test against!" -ForegroundColor Red
    }
    function Write-CustomLog {
        param (
            [string]$Message,
            [object]$InputObject,
            [string]$Level = 'INFO',
            [string]$OutputLevel,
            [string]$LogName,
            [string]$LogDirectory,
            [int]$RotationInterval,
            [switch]$Rotate
        )
        $outFilePath = "$($envSettings.ErrorFilePath).${Level}"
        if ($InputObject) {
            $InputObject | Out-File -FilePath $outFilePath -Force -Append
        }
        if ($Message) {
            $Message | Out-File -FilePath $outFilePath -Force -Append
        }
    }
    $sourceDummyData1 = Import-Csv -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'dummyData1.csv') -Delimiter ';' -Encoding utf8
    $sourceDummyData2 = Import-Csv -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'dummyData2.csv') -Delimiter ';' -Encoding utf8
    $differenceObjectDummy1 = [System.Collections.ArrayList]::new()
    $differenceObjectDummy1.AddRange($sourceDummyData1)
    $referenceObjectDummy1 = [System.Collections.ArrayList]::new()
    $referenceObjectDummy1.AddRange($sourceDummyData1)
    $referenceObjectDummy2 = [System.Collections.ArrayList]::new()
    $referenceObjectDummy2.AddRange($sourceDummyData2)
    $compSettings = [PSCustomObject]@{
        properties = @("username")
        systemViewIdentifier = "systemViewIdentifier"
    }
}
Describe "Invoke-ObjectComparison" -Tag 'function','public'{
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named ReferenceObject that is mandatory and accepts an ArrayList' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ReferenceObject -Mandatory -Type [System.Collections.ArrayList]
    }
    It 'should have a parameter named DifferenceObject that is mandatory and accepts an ArrayList' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter DifferenceObject -Mandatory -Type [System.Collections.ArrayList]
    }
    It 'should have a parameter named CompareSettings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter CompareSettings -Mandatory -Type [PSCustomObject]
    }
    It 'should throw with invalid input' {
        {Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy -DifferenceObject $differenceObjectDummy -CompareSettings $compSettings} | Should -Throw
    }
    It 'should NOT throw with valid input' {
        {Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy1 -DifferenceObject $differenceObjectDummy1 -CompareSettings $compSettings} | Should -Not -Throw
    }
    It 'should return 0 objects with same data' {
        $result = Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy1 -DifferenceObject $differenceObjectDummy1 -CompareSettings $compSettings
        $result.Count | Should -BeExactly 0
    }
    It 'should return 10 objects with same data and IncludeEqual = true' {
        $tempCompSettings = [PSCustomObject]@{
            properties = $compSettings.properties
            IncludeEqual = 'true'
        }
        $result = Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy1 -DifferenceObject $differenceObjectDummy1 -CompareSettings $tempCompSettings
        $result.Count | Should -BeExactly 10
    }
    It 'should return 12 objects when data differs' {
        $tempCompSettings = [PSCustomObject]@{
            properties = $compSettings.properties
        }
        $result = Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy2 -DifferenceObject $differenceObjectDummy1 -CompareSettings $tempCompSettings
        $result.Count | Should -BeExactly 12
    }
    It 'should return 16 objects when data differs and IncludeEqual = true' {
        $tempCompSettings = [PSCustomObject]@{
            properties = $compSettings.properties
            IncludeEqual = $true
        }
        $result = Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy2 -DifferenceObject $differenceObjectDummy1 -CompareSettings $tempCompSettings
        $result.Count | Should -BeExactly 16
    }
    It 'should return 4 objects when data differs, IncludeEqual = true and ExcludeDifferent = true' {
        $tempCompSettings = [PSCustomObject]@{
            properties = $compSettings.properties
            IncludeEqual = $true
            ExcludeDifferent = $true
        }
        $result = Invoke-ObjectComparison -ReferenceObject $referenceObjectDummy2 -DifferenceObject $differenceObjectDummy1 -CompareSettings $tempCompSettings
        $result.Count | Should -BeExactly 4
    }
    AfterEach {
        $tempCompSettings = $null
        $result = $null
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
