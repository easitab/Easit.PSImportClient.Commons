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
    [xml]$icXmlConfig1 = Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'icConfigurationIdentifier1.xml') -Raw
    $icConfig1 = [PSCustomObject]@{
        ItemsPerPosting = $icXmlConfig1.jdbcConfiguration.ItemsPerPosting
        SleepBetweenPostings = $icXmlConfig1.jdbcConfiguration.SleepBetweenPostings
        Identifier = $icXmlConfig1.jdbcConfiguration.Identifier
        Disabled = $icXmlConfig1.jdbcConfiguration.Disabled
        SystemName = $icXmlConfig1.jdbcConfiguration.SystemName
        TransformationXSL = $icXmlConfig1.jdbcConfiguration.TransformationXSL
        ConfigurationType = "jdbcConfiguration"
        ConfigurationTags = $icXmlConfig1.jdbcConfiguration.ConfigurationTags
        DriverClassName = $icXmlConfig1.jdbcConfiguration.driverClassName
    }
    [xml]$icXmlConfigUnknownDriverClass = Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'icConfigurationUnknownDriverClass.xml') -Raw
    $icConfigUnknownDriverClass = [PSCustomObject]@{
        ItemsPerPosting = $icXmlConfigUnknownDriverClass.jdbcConfiguration.ItemsPerPosting
        SleepBetweenPostings = $icXmlConfigUnknownDriverClass.jdbcConfiguration.SleepBetweenPostings
        Identifier = $icXmlConfigUnknownDriverClass.jdbcConfiguration.Identifier
        Disabled = $icXmlConfigUnknownDriverClass.jdbcConfiguration.Disabled
        SystemName = $icXmlConfigUnknownDriverClass.jdbcConfiguration.SystemName
        TransformationXSL = $icXmlConfigUnknownDriverClass.jdbcConfiguration.TransformationXSL
        ConfigurationType = "jdbcConfiguration"
        ConfigurationTags = $icXmlConfigUnknownDriverClass.jdbcConfiguration.ConfigurationTags
        DriverClassName = $icXmlConfigUnknownDriverClass.jdbcConfiguration.driverClassName
    }
    $configurationSettings = (Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1.json') -Raw | ConvertFrom-Json)
    $sourceSettings = $configurationSettings.sources[0]
    $configurationSettingsCombineSourceAttributes = (Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1CombineSourceAttributes.json') -Raw | ConvertFrom-Json)
    $sourceSettingsCombineSourceAttributes = $configurationSettingsCombineSourceAttributes.sources[0]
    $configurationSettingsCombineDisabled = (Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1CombineDisabled.json') -Raw | ConvertFrom-Json)
    $sourceSettingsCombineDisabled = $configurationSettingsCombineDisabled.sources[0]
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
    function Import-Module {
        [CmdletBinding()]
        param (
            $Path,
            [Switch]$Force,
            [Switch]$Global
        )
    }
    function ConvertFrom-ReliqueJdbcCsvCsvDriver {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [PSCustomObject]$ImportClientConfiguration
        )
        
        begin {
            
        }
        
        process {
            #$connectionStringPropertiesObject = [PSCustomObject]@{}
            #return $connectionStringPropertiesObject
        }
        
        end {
            
        }
    }
    function Import-FromCsvSource {
        [CmdletBinding()]
        param (
            [Parameter()]
            [PSCustomObject]$SourceSettings
        )
        
        begin {
            
        }
        
        process {
            return @(
                [PSCustomObject]@{
                    Name1 = 'Value1'
                    Name2 = 'Value2'
                },
                [PSCustomObject]@{
                    Name1 = 'Value1'
                    Name2 = 'Value2'
                }
            )
        }
        
        end {
            
        }
    }
    function Add-NewCombineProperty {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [PSCustomObject]$InputObject,
            [Parameter(Mandatory)]
            [PSCustomObject]$Combine
        )
        
        begin {
            
        }
        
        process {
            $InputObject | Add-Member -MemberType NoteProperty -Name "$($Combine.combineAttributeOutputName)" -Value (New-PropertyValue -Object $InputObject -Attributes $Combine.attributes -CombineCharacter $Combine.character)
        }
        
        end {
            
        }
    }
    function New-PropertyValue {
        [CmdletBinding()]
        param (
            [Parameter()]
            [PSCustomObject]$Object,
            [Parameter()]
            [array]$Attributes,
            [Parameter()]
            [array]$CombineCharacter
        )
        
        begin {
            
        }
        
        process {
            $returnValue = $null
            foreach ($attribute in $Attributes) {
                if ($null -eq $returnValue) {
                    $returnValue = "$($Object."$attribute")"
                } else {
                    $returnValue = "${returnValue}${CombineCharacter}$($Object."$attribute")"
                }
            }
            return $returnValue
        }
        
        end {
            
        }
    }
}
Describe "Invoke-JdbcHandler" -Tag 'function','public' {
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a mandatory parameter named SourceDirectory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter SourceDirectory -Mandatory
    }
    It 'should have a mandatory parameter named ImportClientConfiguration' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ImportClientConfiguration -Mandatory
    }
    It 'should have a mandatory parameter named ConfigurationSourceSettings' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ConfigurationSourceSettings -Mandatory
    }
    It 'should trow if driver classname is unknown / unsupported' {
        {Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfigUnknownDriverClass -ConfigurationSourceSettings $sourceSettings} | Should -Throw
    }
    It 'should NOT throw, not write any warnings or errors and return 2 objects' {
        {Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettings} | Should -Not -Throw
        $result = Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettings
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
        $result.Count | Should -BeExactly 2
    }
    It 'should NOT throw, NOT write any warnings or errors and return objects with the property userName and that should NOT be null or empty.' {
        {Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettingsCombineSourceAttributes} | Should -Not -Throw
        $result = Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettingsCombineSourceAttributes
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
        $result[0].userName | Should -Not -BeNullOrEmpty
    }
    It 'should NOT throw, NOT write any warnings or errors and returned objects should NOT have a property named userName' {
        {Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettingsCombineDisabled} | Should -Not -Throw
        $result = Invoke-JdbcHandler -SourceDirectory $envSettings.SourceDirectory -ImportClientConfiguration $icConfig1 -ConfigurationSourceSettings $sourceSettingsCombineDisabled
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
        $result[0].userName | Should -BeNullOrEmpty
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}