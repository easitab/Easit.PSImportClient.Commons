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
    function Test-Configuration {
        param (
            [String]$Json
        )
        if ($null -eq $Json -or [String]::IsNullOrEmpty($Json)) {
            Write-CustomLog -Message "configuration is null" -Level ERROR
            throw
        }
        try {
            $configurationSchema = Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'configuration.schema.json'
            $null = Test-Json -Json $Json -SchemaFile $configurationSchema -ErrorAction Stop
        } catch {
            Write-CustomLog -Message "Json failed validation agains schema" -Level WARN
            Write-CustomLog -InputObject $_ -Level ERROR
            throw
        }
    }
}
Describe "Get-Configuration" -Tag 'function','public' {
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named PsImportClientDirectory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter PsImportClientDirectory
    }
    It 'that is not mandatory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter PsImportClientDirectory -Not -Mandatory
    }
    It 'should have a parameter named ConfigurationFile' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ConfigurationFile
    }
    It 'that is not mandatory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ConfigurationFile -Not -Mandatory
    }
    It 'should throw if both parameters are null' {
        {Get-Configuration} | Should -Throw
    }
    It 'should throw if path does not exist' {
        {Get-Configuration -PsImportClientDirectory 'H:\testDirectory'} | Should -Throw
    }
    It 'should warn if path does not exist' {
        {Get-Configuration -ConfigurationFile 'H:\testDirectory\config.json'} | Should -Not -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -Not -BeNullOrEmpty
    }
    It 'should not throw and return 0 configs when configuration is invalid' {
        {$configs = Get-Configuration -ConfigurationFile (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'invalidConfiguration.json')} | Should -Not -Throw
        $configs.Count | Should -BeExactly 0
    }
    It 'should not throw with valid configuration' {
        {Get-Configuration -ConfigurationFile (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1.json')} | Should -Not -Throw
    }
    It 'should return 1 configuration' {
        $configs = Get-Configuration -ConfigurationFile (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1.json')
        $configs.Count | Should -BeExactly 1
    }
    It 'should return 2 configuration' {
        $config1 = Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1.json'
        $config2 = Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration2.json'
        $configs = Get-Configuration -ConfigurationFile $config1, $config2
        $configs.Count | Should -BeExactly 2
    }
    It 'should throw if configurations directory does not exist' {
        {Get-Configuration -PsImportClientDirectory $envSettings.TestDataDirectory} | Should -Throw
    }
    AfterEach {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Force -Confirm:$false
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}