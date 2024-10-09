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
    try {
        $jsonContent = Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1.json') -Raw -ErrorAction Stop
        $invalidJsonContent = Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'invalidConfiguration.json') -Raw -ErrorAction Stop
    } catch {
        throw
    }
}
Describe "Test-Configuration" -Tag 'function','public' {
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named Json' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Json
    }
    It 'that is mandatory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Json -Mandatory
    }
    It 'should throw if parameter is null' {
        {Test-Configuration -Json $null} | Should -Throw
    }
    It 'should throw if parameter is null' {
        {Test-Configuration -Json $null} | Should -Throw
    }
    It 'should throw and write error if schema is not found' {
        {Test-Configuration -Json $jsonContent} | Should -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -Not -BeNullOrEmpty
    }
    It 'should not throw, not write error or warn if test is OK' {
        {Test-Configuration -Json $jsonContent -SchemaDirectory $envSettings.TestDataDirectory} | Should -Not -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix | Should -Not -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
    }
    It 'should throw, write error and warn if test fails' {
        {Test-Configuration -Json $invalidJsonContent -SchemaDirectory $envSettings.TestDataDirectory} | Should -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -Not -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -Not -BeNullOrEmpty
    }
    AfterEach {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw $_
    }
}