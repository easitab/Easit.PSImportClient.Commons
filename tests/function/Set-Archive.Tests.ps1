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
    $testArchiveSettings = [PSCustomObject]@{
        directory = (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'tempLogs')
        rotationInterval = 15
    }
    $tempLogFile = Join-Path $testArchiveSettings.directory -ChildPath 'logfile'
}
Describe "Set-Archive" -Tag 'function','public' {
    BeforeEach {
        if (Test-Path -Path $testArchiveSettings.directory) {

        } else {
            $null = New-Item -Path $envSettings.TestDataDirectory -Name 'tempLogs' -ItemType Directory
        }
        if (Test-Path -Path (Join-Path $testArchiveSettings.directory -ChildPath 'logfile')) {
            $tempLogFile = Join-Path $testArchiveSettings.directory -ChildPath 'logfile'
        } else {
            $null = New-Item -Path $testArchiveSettings.directory -Name 'logfile' -ItemType File -Value 'templogfile'
        }
    }
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named ArchiveSettings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ArchiveSettings -Mandatory -Type [PSCustomObject]
    }
    It 'should not throw when input is valid' {
        {Set-Archive -ArchiveSettings $testArchiveSettings} | Should -Not -Throw
    }
    It 'should remove files older then testArchiveSettings.rotationInterval' {
        $tempLogFile = Get-Item -Path $tempLogFile
        $tempLogFile.CreationTime = ((Get-Date).AddDays(-($testArchiveSettings.rotationInterval+1)))
        Set-Archive -ArchiveSettings $testArchiveSettings
        Get-LogFile -Path $testArchiveSettings.directory | Should -BeNullOrEmpty
    }
    AfterEach {
        $tempLogFile = $null
        Get-ChildItem -Path $testArchiveSettings.directory -Recurse -File | Remove-Item -Confirm:$false
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $testArchiveSettings.directory -Recurse -File | Remove-Item -Confirm:$false
        Get-ChildItem -Path $envSettings.TestDataDirectory -Directory -Include 'tempLogs' -Recurse | Remove-Item -Confirm:$false
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
