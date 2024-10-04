function Write-CustomLog {
    <#
    .SYNOPSIS
        Writes input to file and a output stream.
    .DESCRIPTION
        This function provide the option to log output and / or progress in scripts.
        While there are functions like *Start-Transcript* and *Out-File*, *Write-CustomLog* also handles log rotation and naming of log history.

        *Write-CustomLog* will always append *_date* to the logname and remove logs older than the value of *RotationInterval*.

        *Write-CustomLog* uses *Out-File* for writing output to a file and then redirects either *Message* or *InputObject* to the stream corresponding with the value of *Level*.

        * If no input is provided for *-LogName*, *-LogDirectory* nor *-RotationInterval* the function will look for a variable named LoggerSettings in the global scope with a property or key with the same name and use that value.
        * If no input is provided for *-LogName*, the name of the caller script is used as input.
        * If no input is provided for *-LogDirectory*, logs will be written to $pwd.
        * If no input is provided for *-RotationInterval*, 30 will used as value.
    .PARAMETER Message
        String that will be written to file and stream.
    .PARAMETER InputObject
        The object that will be written to file and stream.
    .PARAMETER Level
        What stream should the input be redirected to.
    .PARAMETER OutputLevel
        What level of input should be written to file and stream.
    .PARAMETER LogName
        Name of logfile.
    .PARAMETER LogDirectory
        In what directory should logs be saved.
    .PARAMETER RotationInterval
        For how many days should logs be kept on disk.
    .PARAMETER Rotate
        Tells the function to rotate logs. If this is always included with *Write-CustomLog* it will always try to rotate logs each time *Write-CustomLog* is invoked.
    .EXAMPLE
        Write-CustomLog -Message "Staring script"

        In this example we write the string *Starting script* as a log entry with the level of INFO.
        It will also use Write-Information to output it to the correct stream.
    .EXAMPLE
        Write-CustomLog -InputObject $_ -Level ERROR

        In this example we write the current objekt to as a log entry with the level of ERROR.
        It will also use Write-Error to output it to the correct stream.
    .EXAMPLE
        Write-CustomLog -Message "Rotating logs" -Level VERBOSE -Rotate

        In this example we write the string *Starting script* as a log entry with the level of INFO.
        It will also use Write-Information to output it to the correct stream.
        Since we specify *-Rotate* the function will try to remove files older than set by *RotationInterval*.
    .EXAMPLE
        Write-CustomLog -Message "Starting script and rotating logs" -Rotate
        Write-CustomLog -Message "Trying something" -Level VERBOSE
        try {
            try-something
        } catch {
            Write-CustomLog -InputObject $_ -Level ERROR
            return
        }
        Write-CustomLog -Message "Script end"

        Basic *real world* example of how to use *Write-CustomLog* in a script.
    .INPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)

        [System.Object](https://learn.microsoft.com/en-us/dotnet/api/system.object)
    .OUTPUTS
        None. This function returns no output.
    #>
	[CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/writecustomlog/')]
    [OutputType()]
	Param (
		[Parameter(ValueFromPipeline,ParameterSetName='string')]
        [string]$Message,
		[Parameter(ValueFromPipeline,ParameterSetName='object')]
        [object]$InputObject,
		[Parameter()]
        [ValidateSet('ERROR','WARN','INFO','VERBOSE','DEBUG')]
		[string]$Level = 'INFO',
        [Parameter()]
        [ValidateSet('ERROR','WARN','INFO','VERBOSE','DEBUG')]
		[string]$OutputLevel,
		[Parameter()]
		[string]$LogName,
		[Parameter()]
		[string]$LogDirectory,
		[Parameter()]
		[int]$RotationInterval,
        [Parameter()]
        [switch]$Rotate
	)
    begin {
        Write-Verbose "$($MyInvocation.MyCommand) begin"
    }
    process {
        try {
            $callStack = Get-PSCallStack
            $function = $callStack[1].Command
            $lineNumber = $MyInvocation.ScriptLineNumber
        } catch {

        }
        if (!($null -eq (Get-Variable -Name 'psImportClient_loggerSettings' -ErrorAction 'SilentlyContinue'))) {
            $loggerSettings = Get-Variable -Name 'psImportClient_loggerSettings' -ValueOnly
        }
        if ($loggerSettings.disabled -eq 'true') {
            break
        }
        if ([string]::IsNullOrWhiteSpace($LogName)) {
            if (!([string]::IsNullOrWhiteSpace($loggerSettings.LogName))) {
                $LogName = $loggerSettings.LogName
            } else {
                $LogName = $callStack[1].Command.TrimEnd('\.ps1')
            }
        }
        if ([string]::IsNullOrWhiteSpace($OutputLevel)) {
            if (!([string]::IsNullOrWhiteSpace($loggerSettings.LoggingLevel))) {
                $OutputLevel = $loggerSettings.LoggingLevel
            } else {
                $OutputLevel = 'INFO'
            }
        }
        if ([string]::IsNullOrWhiteSpace($Level)) {
            $Level = 'INFO'
        }
        $AdjustedLevel = $Level
        switch($AdjustedLevel){
            'INFO' {$AdjustedLevel = 'INFO   '}
            'DEBUG' {$AdjustedLevel = 'DEBUG  '}
            'ERROR' {$AdjustedLevel = 'ERROR  '}
            'WARN' {$AdjustedLevel = 'WARN   '}
        }
        if ($Level -eq 'ERROR' -and !($psImportClient_notificationSettings.sendNotification) -and !($null -eq $psImportClient_notificationSettings)) {
            $psImportClient_notificationSettings.sendNotification = $true
        }
        if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
            $curLoc = (Get-Location).Path
            if (!([string]::IsNullOrWhiteSpace($loggerSettings.LogDirectory))) {
                $LogDirectory = Join-Path -Path $curLoc -ChildPath $loggerSettings.LogDirectory
            } else {
                $LogDirectory = Join-Path -Path $curLoc -ChildPath 'logs'
            }
        }
        if ([string]::IsNullOrWhiteSpace("$RotationInterval")) {
            if (!([string]::IsNullOrWhiteSpace("$($loggerSettings.RotationInterval)"))) {
                $RotationInterval = $loggerSettings.RotationInterval
            } else {
                $RotationInterval = 30
            }
        }
        $LogLevelTable = @{
            ERROR = 1
            WARN = 2
            INFO = 3
            VERBOSE = 4
            DEBUG = 5
        }
        $today = Get-Date -Format "yyyyMMdd"
        $LogName = "${LogName}_${today}.log"
        $logOutputPath = Join-Path -Path "$LogDirectory" -ChildPath "$LogName"
        $outfileParams = @{
            FilePath = "$logOutputPath"
            Encoding = 'UTF8'
            Append = $true
            NoClobber = $true
        }
        if ($Level -eq 'ERROR' -and $null -eq $psImportClient_notificationSettings.logFilepath -and !($null -eq $psImportClient_notificationSettings)) {
            $psImportClient_notificationSettings.logFilepath = $outfileParams.FilePath
        }
        if ($Rotate) {
            $logArchiveFiles = Get-ChildItem -Path "$LogDirectory" -Recurse  -Include "*${logname}*.log"
            foreach ($logArchiveFile in $logArchiveFiles) {
                if ($logArchiveFile.CreationTime -lt ((Get-Date).AddDays(-$RotationInterval))) {
                    "$($logArchiveFile.Name) is older than $RotationInterval days, removing.." | Out-File @outfileParams
                    try {
                        Remove-Item "$($logArchiveFile.FullName)" -Force
                    } catch {
                        Write-Error $_
                        exit
                    }
                    "$FormattedDate - INFO   - Removed $($logArchiveFile.Name)" | Out-File @outfileParams
                }
            }
        }
        if ($LogLevelTable."$Level" -le $LogLevelTable."$OutputLevel") {
            $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $PSStyle.OutputRendering = 'PlainText'
            if (!(Test-Path $logOutputPath)) {
                $NewLogFile = New-Item "$logOutputPath" -Force -ItemType File
                "$FormattedDate - INFO   - Created $NewLogFile [$function @ $lineNumber]" | Out-File @outfileParams
            }
            if ($Message) {
                "$FormattedDate - $AdjustedLevel - $Message [$function @ $lineNumber]" | Out-File @outfileParams
            }
            if ($InputObject) {
                "$FormattedDate - $AdjustedLevel - InputObject [$function @ $lineNumber]" | Out-File @outfileParams
                $InputObject | Out-File @outfileParams
            }
        }
    }
    end {
        Write-Verbose "$($MyInvocation.MyCommand) end"
    }
}