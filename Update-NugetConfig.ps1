#Set-StrictMode -Version Latest
#####################################################
# Update-NugetConfig
#####################################################
<#PSScriptInfo


.VERSION 0.1

.GUID e7172940-4e12-425e-9e65-c7ab1b2ffc1f

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell script

.LICENSEURI https://github.com/Radical-Dave/Update-NugetConfig/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/Update-NugetConfig

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.SYNOPSIS
Powershell Script to Update Nuget.config edits 

.DESCRIPTION
Powershell Script to Update Nuget.config, set repositoryPackage, remove local packages

.EXAMPLE
PS> .\Update-NugetConfig -repositoryPath '/packages'

.EXAMPLE
PS> .\Update-NugetConfig -repositoryPath '/packages' -force -replace -remove

.Link
https://github.com/Radical-Dave/Update-NugetConfig

.OUTPUTS
    System.String
#>
#####################################################
# Update-NugetConfig
#####################################################
[CmdletBinding(SupportsShouldProcess,PositionalBinding=$false)]
Param(
    # Path to find $name
	[Parameter(Mandatory=$false, Position=0)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] [string]$path,
	# Name of file default [nuget.config]
	[Parameter(Mandatory=$false, Position=0)] [string]$name = 'nuget.config',
    # RepositoryPath - configuration.config.repositoryPath value
	[Parameter(Mandatory=$false)] [string]$repositoryPath,

    #coming soon:
    # PackageSources (optional) replaces all PackageSources with those provided
	#[Parameter(Mandatory=$false)] [hashtable]$packageSources,
    # ActivePackageSources (optional) adds all new ActivePackageSources with those provided
	#[Parameter(Mandatory=$false)] [hashtable]$activePackageSources,

    # Force - overwrite if index already exists
    [Parameter(Mandatory=$false)] [switch]$force = $false,
    # Recurse - look in all child folders
    [Parameter(Mandatory=$false)] [switch]$recurse = $false,
    # Remove - used to remove existing packages folder if moving
    [Parameter(Mandatory=$false)] [switch]$remove = $false
)
begin {
	$ErrorActionPreference = 'Stop'
	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
    if(!$path) { $path = Get-Location }
	Write-Verbose "$PSScriptName $path $name"
}
process {	
	Write-Verbose "$PSScriptName $path $name $template start"
    if($PSCmdlet.ShouldProcess($path)) {
        try {
            $files = Get-ChildItem -path $path -include $name -Recurse
            foreach($file in $files) {
                try {
                    Write-Host " # Processing:$file" -ForegroundColor Yellow
                    $xml = [xml](Get-Content $file)

                    $xmlOriginal = $xml
                    $xmlDirty = $false
                    #$repositoryPathCurrent = Select-Xml -xml $xml -XPath "//configuration/config/add[@key='repositoryPath']/@value"
                    #$repositoryPathCurrent = ($xml.configuration.config.add | Where-Object {$_.Key -eq 'repositoryPath'}).Value
                    #$repositoryPathNode = $xml.configuration.config.add | Where-Object {$_.Key -eq 'repositoryPath'}
                    $repositoryPathNode = $xml.SelectSingleNode("//configuration/config/add[@key = 'repositoryPath']")
                    $repositoryPathCurrent = $repositoryPathNode.Value
                    Write-Host " # Current repositoryPath:$repositoryPathCurrent" -ForegroundColor Yellow
                    if ($repositoryPathCurrent -and $repositoryPath -and $repositoryPath -ne $repositoryPathCurrent) {
                        $repositoryPathNode.SetAttribute("value", $repositoryPath)
                        $repositoryPathNode.value = $repositoryPath
                        Write-Host " # Updated repositoryPathNode:$repositoryPath" -ForegroundColor Green
                        Write-Host " # Updated repositoryPathNode:$($repositoryPathNode.value)" -ForegroundColor Green
                        $xmlDirty = $true                      
                    } else {
                        ## needs to be added?
                    }

                    if ($xml -eq $xmlOriginal -and !$xmlDirty) {
                        Write-Host " # No changes to $file were detected" -ForegroundColor Yellow
                    } else {
                        $xml.Save($file)
                        Write-Host " # $file updated" -ForegroundColor Green
                        #Write-Verbose " # file:$xml"

                        if ($remove) {
                            $xmlPath = Split-Path $file -Parent
                            $packagesLocal = Join-Path $xmlPath "packages"
                            if ($packagesLocal -and $repositoryPath -ne $packagesLocal -and (Test-Path $packagesLocal)) {
                                Write-Verbose " # Removing: $packagesLocal"
                                Remove-Item $packagesLocal -Recurse
                            }
                        }
                    }                 
                }
                catch {
                    Write-Host "$PSScriptName Error Occured:$($PSItem.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "$PSScriptName Error Occured:$($PSItem.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Verbose "$PSScriptName $name end"
    return $results
}