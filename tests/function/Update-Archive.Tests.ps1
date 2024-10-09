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
    function Test-ArchiveSettings {
        param (
            [Parameter(Mandatory)]
            [PSCustomObject]$Settings
        )
        if ($Settings.ThrowOnTest) {
            throw "throw from Test-ArchiveSettings"
        }
    }
    function Add-FileToArchive {
        param (
            [Parameter(Mandatory)]
            [string]$ArchiveDirectory,
            [Parameter(Mandatory)]
            [string]$FileToArchive,
            [Parameter(Mandatory)]
            [string]$ConfigurationName,
            [Parameter(Mandatory)]
            [string]$SourceName
        )
        if ($ConfigurationName -eq 'true') {
            throw "throw from Add-FileToArchive"
        }
    }
    function Set-Archive {
        param (
            [Parameter(Mandatory)]
            [PSCustomObject]$ArchiveSettings
        )
        if ($ArchiveSettings.ThrowOnTest) {
            throw "throw from Set-Archive"
        }
    }
    $archiveSettingsTrue = [PSCustomObject]@{
        ThrowOnTest = $true
        directory = 'archive'
    }
    $archiveSettingsFalse = [PSCustomObject]@{
        ThrowOnTest = $false
        directory = 'archive'
    }
    $configNameTrue = 'true'
    $configNameFalse = 'false'
    $fileToArchive = Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'PSImportClient-Tests-temp'
    $fileToArchiveFalse = 'false'
    
}
Describe "Update-Archive" -Tag 'function','public'{
    BeforeEach {
        if (Test-Path $fileToArchive) {

        } else {
            $null = New-Item -Path $fileToArchive -ItemType File -Force
        }
    }
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named ArchiveSettings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ArchiveSettings -Mandatory -Type [PSCustomObject]
    }
    It 'should have a parameter named FileToArchive that accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter FileToArchive -Type [String]
    }
    It 'should have a parameter named ConfigurationName that accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ConfigurationName -Type [String]
    }
    It 'should have a parameter named SourceName that accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter SourceName -Type [String]
    }
    It 'should have a parameter named AddToArchive that is a switch' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter AddToArchive -Type [switch]
    }
    It 'should have a parameter named RotateArchive that is a switch' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter RotateArchive -Type [switch]
    }
    It 'should NOT throw or do anything' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsTrue
            FileToArchive = $fileToArchiveFalse
            ConfigurationName = $configNameFalse
            SourceName = 'SourceName'
        }
        {Update-Archive @tempParams} | Should -Not -Throw
    }
    It 'should throw with exact error (throw from Test-ArchiveSettings)' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsTrue
            FileToArchive = $fileToArchiveFalse
            ConfigurationName = $configNameFalse
            SourceName = 'SourceName'
            AddToArchive = $true
        }
        {Update-Archive @tempParams} | Should -Throw -ExpectedMessage 'throw from Test-ArchiveSettings'
    }
    It 'should throw with exact error (throw from Add-FileToArchive)' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsFalse
            FileToArchive = $fileToArchiveFalse
            ConfigurationName = $configNameTrue
            SourceName = 'SourceName'
            AddToArchive = $true
        }
        {Update-Archive @tempParams} | Should -Throw -ExpectedMessage 'throw from Add-FileToArchive'
    }
    It 'should throw and stop if Remove-Item fails' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsFalse
            FileToArchive = $fileToArchiveFalse
            ConfigurationName = $configNameFalse
            SourceName = 'SourceName'
            AddToArchive = $true
        }
        {Update-Archive @tempParams} | Should -Throw
    }
    It 'should throw and stop if Set-Archive fails' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsTrue
            FileToArchive = $fileToArchiveFalse
            ConfigurationName = $configNameFalse
            SourceName = 'SourceName'
            AddToArchive = $false
            RotateArchive = $true
        }
        {Update-Archive @tempParams} | Should -Throw
    }
    It 'should NOT throw or stop' {
        $tempParams = @{
            ArchiveSettings = $archiveSettingsFalse
            FileToArchive = $fileToArchive
            ConfigurationName = $configNameFalse
            SourceName = 'SourceName'
            AddToArchive = $true
            RotateArchive = $true

        }
        {Update-Archive @tempParams} | Should -Not -Throw
    }
    AfterEach {
        $tempParams = $null
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
