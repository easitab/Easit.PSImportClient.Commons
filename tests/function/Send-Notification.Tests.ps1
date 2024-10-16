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
    function Send-MailMessage {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [String]$To,
            [Parameter(Mandatory)]
            [String]$From,
            [Parameter(Mandatory)]
            [String]$SmtpServer,
            [Parameter()]
            [Int]$Port,
            [Parameter()]
            [String]$Encoding,
            [Parameter(Mandatory)]
            [String]$Subject,
            [Parameter(Mandatory)]
            [String]$Body,
            $Credential,
            [Parameter()]
            [switch]$UseSsl,
            [Parameter()]
            [String]$Attachments
        )
        
    }
    $validfunctionSmtpSettings1 = [PSCustomObject]@{
        enabled = $false
        type = "smtp"
        SmtpServer = "smtp.domain.com"
        Port = 993
        To = "to@domain.com"
        From = "from@domain.com"
        Subject = "a subject"
        username = "myUsername"
        password = "myPassword"
    }
    $validfunctionSmtpSettings2 = [PSCustomObject]@{
        enabled = $false
        type = "smtp"
        SmtpServer = "smtp.domain.com"
        Port = 993
        To = "to@domain.com"
        From = "from@domain.com"
        Subject = "a subject"
        username = "myUsername"
        password = "myPassword"
    }
    $invalidfunctionSmtpSettings1 = [PSCustomObject]@{
        enabled = $false
        type = "smtp"
        SmtpServer = "smtp.domain.com"
        Port = 993
        To = "to@domain.com"
        From = "from@domain.com"
        Subject = "a subject"
        username = "myUsername"
        password = ""
    }
    $invalidfunctionSmtpSettings2 = [PSCustomObject]@{
        enabled = $false
        type = "smtp2"
    }
    $loggerSettings = @{
        LogDirectory = $envSettings.TestDataDirectory
        LogName = 'tempLog.log'
    }
    $tempLogFile = New-Item -Path $envSettings.TestDataDirectory -Name 'tempLog.log' -ItemType File -Force
}
Describe "Send-Notification" -Tag 'function','public' {
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named Settings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Settings -Mandatory -Type [PSCustomObject]
    }
    It 'should NOT throw' {
        {Send-Notification -Settings $validfunctionSmtpSettings1} | Should -Not -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
    }
    It 'should throw' {
        {Send-Notification -Settings $invalidfunctionSmtpSettings1} | Should -Throw
    }
    It 'should throw with expected message' {
        {Send-Notification -Settings $invalidfunctionSmtpSettings2} | Should -Throw -ExpectedMessage "Unknown notification type ($($invalidfunctionSmtpSettings2.type))"
    }
    AfterEach {
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix | Remove-Item -Confirm:$false
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($loggerSettings.LogName)" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
