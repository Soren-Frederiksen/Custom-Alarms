<#

.NAME
    Get-LR-Cases-Report
	
	Written by:   Soren Frederiksen
	Date:         November 9 2022	

.SYNOPSIS
    Generate a report showing LogRhythm Cases activity

.DESCRIPTION
	The program uses LogRhythm Tools to connect to a LogRhythm deployment and generates a report showing Case Management activity for a specific day
	
.PARAMETER currentDate
	Optional - Specifies which day you want to use for the report, and if no date is specified it will used the current day.
	
	Format -  yyyyy-MM-dd

.PARAMETER outputPath
	Folder where output file will be written to.  Must end with a "\"
	
.OUTPUT
	Writes to the screen the following information
		Number of SIEM Cases opened:
		Number of SIEM Cases closed:
		Number of Siem Cases unassigned:
		Number of Siem Cases assigned:

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

# Array of Cases that should not be included in the count.
# The Cases are case sensitive and so must make sure to use it in the correct case.

$ignoreCase = @("Networkx",
                 "third rule"
                 )

if ($currentDate -eq "" )
    {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
    }
	
# Specify Output File in the form  Cases-<date>.txt
$outputFile = "$outputPath" + "Cases-" + "$currentDate" + ".txt"

# Now set $caseDate to be one less than current day.  
#    Will use this date to run Get-LRCases.  This is because the Alarms are returned in UTC time and so you want to make sure to include all days

$caseDate = (Get-Date $currentDate).AddDays(-1)

# Now need to set a start and end times for collecting alarms based on UTC time
$startDate = (Get-Date $currentDate).ToUniversalTime()
[datetime]$startDate = Get-Date $startdate -Format ("yyyy-MM-ddThh:mm:ss")
$endDate = (Get-Date $currentDate).Adddays(1).ToUniversalTime()
$endDate = Get-Date $enddate -Format ("yyyy-MM-ddThh:mm:ss")


<# Run Get-LrCases and collect all logs based on $alarmDate 
      Output from Get-LrAlarms looks as follows:
			id                      : EBC2429C-986C-4EF1-867B-B1DF24A64B91
			number                  : 1
			externalId              :
			dateCreated             : 2022-06-27T10:56:50.4162958Z
			dateUpdated             : 2022-07-21T12:28:52.01968Z
			dateClosed              :
			owner                   : @{number=17; name=Chambers, Daniel Test; disabled=False}
			lastUpdatedBy           : @{number=13; name=20220601-3-api; disabled=False}
			name                    : Test Case for notifications
			status                  : @{name=Incident; number=3}
			priority                : 4
			dueDate                 : 2022-06-28T10:56:41Z
			resolution              :
			resolutionDateUpdated   :
			resolutionLastUpdatedBy :
			summary                 :
			entity                  : @{number=-100; name=Global Entity; fullName=Global Entity}
			collaborators           : {@{number=10; name=Chambers, Daniel; disabled=False}, @{number=17; name=Chambers, Daniel
									Test; disabled=False}, @{number=14; name=20220607-api-dc; disabled=False}}
			tags                    : {@{number=1; text=test tag}}
	Need to filter out logs based on dateInserted 
	Also, need to sort based on alarmId and make sure sure all entries are unique.
#>

#$allAlarms = Get-LrAlarms -ResultsOnly -DateInserted $alarmDate| Where-Object dateInserted -ge $startDate | Where-Object dateInserted -le $endDate | sort-object alarmId -unique

$allCases = Get-LrCases
#
if ($allCases.Error -eq $true) 
{
    return $allCases
} else 
{
	$todaysCases = Get-LrCases -CreatedAfter $startDate -CreatedBefore $startDate.AddDays(1)
	if ($todaysCases.Error -eq $true) 
	{
 	   return $todaysCases
	}
	$closedCases = $todaysCases | where-object dateclosed -CNotlike ""
	$allClosedCases = $allCases | where-object dateclosed -CNotlike ""
	$casesOpen = $allCases.count - $allClosedCases.count
}

<#
# Do not include any alarms included in the IgnoreAlarms  array
foreach ($ignore in $ignorealarm)
{
    $allAlarms = $allAlarms | Where-Object alarmRuleName -CNotlike "*$ignore*"
}
#>

# Output a summary of all alarm data counts.
if ($outputPath)
{
	Write-Host "`nWriting to file"
	"SIEM Case Summary for  $currentDate" | Out-File -FilePath $outputFile
	"Number of SIEM  Total number of Cases:		" + $todaysCases.count  | Out-File -FilePath $outputFile
	"Number of SIEM Cases opened today:			" + $todaysCases.count  | Out-File -FilePath $outputFile
	"Number of SIEM Cases closed today:			" + $closedCases.count  | Out-File -FilePath $outputFile -Append
	"Number of SIEM Cases still Open:			" + $casesOpen  | Out-File -FilePath $outputFile -Append
#	"Number of Siem Alarms assigned:        " + @($assignedAlarms).count  | Out-File -FilePath $outputFile -Append
}
else
{
	Write-Host "SIEM Alarm Summary for  $currentDate"
	Write-Host "Number of SIEM Cases:                 " $allCases.count
	Write-Host "Number of SIEM Cases opened today:    " $todaysCases.count
	Write-Host "Number of SIEM Cases closed today:    " $closedCases.count
	Write-Host "Number of SIEM cases stll open:       " $casesOpen
#	Write-Host "Number of Siem Alarms assigned:       " @($assignedAlarms).count
}