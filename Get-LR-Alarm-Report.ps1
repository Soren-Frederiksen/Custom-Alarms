<#

.NAME
    Get-LR-Alarm-Report
	
	Written by:   Soren Frederiksen
	Date:         November 3 2022	

.SYNOPSIS
    Generate a report showing alarm activity

.DESCRIPTION
	The program uses LogRhythm Tools to connect to a LogRhythm deployment and generates a report showing alarm activity for a specific day
	
.PARAMETER currentDate
	Optional - Specifies which day you want to use for the report, and if no date is specified it will used the current day.
	
	Format -  yyyyy-MM-dd

.PARAMETER outputPath
	FOlder where output file will be written to.  Must end with a "\"
	
.OUTPUT
	Writes to the screen the following information
		Number of SIEM Alarms opened:
		Number of SIEM Alarms closed:
		Number of Siem Alarms unassigned:
		Number of Siem Alarms assigned:

.EXAMPLE
	PS C:\> .\Get-LR-Alarm-Report.ps1 -currentDate 2022-10-19
	SIEM Alarm Summary for  2022-10-19
	Number of SIEM Alarms opened:          256
	Number of SIEM Alarms closed:          0
	Number of Siem Alarms unassigned:      252
	Number of Siem Alarms assigned:        4

.LINK
	https://github.com/LogRhythm-Tools/LogRhythm.Tools

#>

param(

  [Parameter(Mandatory=$false)] [string]$currentDate = '',
  [Parameter(Mandatory=$false)] [string]$outputPath = ''
 
)

Import-Module logrhythm.tools

# Array of Alarm rules that should not be included in the count.

$ignoreAlarm = @("Networkx",
                 "third rule"
                 )

if ($currentDate -eq "" )
    {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
    }
	
# Specify Output File in the form  Alarms-<date>.txt
$outputFile = "$outputPath" + "Alarms-" + "$currentDate" + ".txt"

# Now set $alarmDate to be one less than current day.  
#    Will use this date to run Get-LRAlarms.  This is because the Alarms are returned in UTC time and so you want to make sure to include all days

$alarmDate = (Get-Date $currentDate).AddDays(-1)

# Now need to set a start and end times for collecting alarms based on UTC time
$startDate = (Get-Date $currentDate).ToUniversalTime()
$startDate = Get-Date $startdate -Format ("yyyy-MM-ddThh:mm:ss")
$endDate = (Get-Date $currentDate).Adddays(1).ToUniversalTime()
$endDate = Get-Date $enddate -Format ("yyyy-MM-ddThh:mm:ss")


<# Run Get-LrAlarms and collect all logs based on $alarmDate 
      Output from Get-LrAlarms looks as follows:
			alarmId         : 256
			alarmRuleName   : AIE: Network Connection Observed
			alarmStatus     : 0
			alarmDataCached : Y
			associatedCases : {}
			entityName      : Global Entity
			dateInserted    : 2022-10-20T05:58:37.533
	Need to filter out logs based on dateInserted 
	Also, need to sort based on alarmId and make sure sure all entries are unique.
#>

$allAlarms = Get-LrAlarms -ResultsOnly -DateInserted $alarmDate| Where-Object dateInserted -ge $startDate | Where-Object dateInserted -le $endDate | sort-object alarmId -unique

# Do not include any alarms in cluded in the IgnoreAlarms  array
foreach ($ignore in $ignorealarm)
    {
        $allAlarms = $allAlarms | Where-Object alarmRuleName -CNotlike "*$ignore*"
    }


<# Now collect alarms of each status types (types 1-9)
AlarmStatus		AlarmStatusName
0				New
1				Open: Open
2				Open: Working
3				Open: Escalated
4				Closed: Closed
5				Closed: False Alarm
6				Closed: Monitor
7				Closed: Reported
8				Closed: Resolved
9				Closed: Unresolved
#>

$newAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 0 
$openedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 1
$workingAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 2
$escalatedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 3
$closedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 4
$falseAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 5
$monitorAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 6
$reportedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 7
$resolvedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 8
$unresolvedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 9

# Now get all those alarms tht have been assigned to a case
$assignedAlarms = $allAlarms | Where -Property associatedCases -ne ""

# Now sum up all the alarm types
$totalOpenedAlarms = @($newAlarms).count + @($openedAlarms).count + @($workingAlarms).count + @($escalatedAlarms).count
$totalClosedAlarms = @($closedAlarms).count + @($falseAlarms).count + @($monitorAlarms).count + @($reportedAlarms).count + @($resolvedAlarms).count + @($unresolvedAlarms).count
$unassignedAlarms = @($allAlarms).count - @($assignedAlarms).count


# Output a summary of all alarm data counts.
if ($outputPath)
{
	Write-Host "`nWriting to file"
	"SIEM Alarm Summary for  $currentDate" | Out-File -FilePath $outputFile
	"Number of SIEM Alarms opened:          " + $totalOpenedAlarms  | Out-File -FilePath $outputFile -Append
	"Number of SIEM Alarms closed:          " + $totalClosedAlarms  | Out-File -FilePath $outputFile -Append
	"Number of Siem Alarms unassigned:      " + $unassignedAlarms  | Out-File -FilePath $outputFile -Append
	"Number of Siem Alarms assigned:        " + @($assignedAlarms).count  | Out-File -FilePath $outputFile -Append
}
else
{
	Write-Host "SIEM Alarm Summary for  $currentDate"
	Write-Host "Number of SIEM Alarms opened:         " $totalOpenedAlarms
	Write-Host "Number of SIEM Alarms closed:         " $totalClosedAlarms
	Write-Host "Number of Siem Alarms unassigned:     " $unassignedAlarms
	Write-Host "Number of Siem Alarms assigned:       " @($assignedAlarms).count
}