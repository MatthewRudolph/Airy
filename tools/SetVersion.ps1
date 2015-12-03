$globalAssemblyFile = "GlobalAssemblyInfo.cs"
$globalAssemblyVersion = Get-Content .\$globalAssemblyFile

$hasAssemblyVersion = "'"+$globalAssemblyVersion+"'" -match 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'

if (!$hasAssemblyVersion)
{
	Add-AppveyorMessage -Message "No AssemblyVersion found, using 1.0.0.0 instead."
	
	$major=1
	$minor=0
	$build=0 ##Patch
	$revision=0 ##Build
}
else
{
	$assemblyVersionFormattedCorrectly = $matches[0] -match "(?<major>[0-9]+)\.(?<minor>[0-9])+(\.(?<build>([0-9])))?(\.(?<revision>([0-9])))?"
	
	if (!$assemblyVersionFormattedCorrectly) 
	{
		Add-AppveyorMessage -Message "The Global Assembly Version is not formatted correctly."
		return;
	}
	
	$major=$matches['major'] -as [int]
	$minor=$matches['minor'] -as [int]
	$build=$matches['build'] -as [int]
	$revision=$matches['revision'] -as [int]
}

$AssemblyVersion = "$major.$minor.$build.$revision"

Add-AppveyorMessage -Message "Global Assembly Version: $AssemblyVersion ."

$AssemblyFileVersion = "$major.$minor.$env:APPVEYOR_BUILD_NUMBER"
$AssemblyInformationalVersion = "$AssemblyFileVersion-$env:APPVEYOR_REPO_SCM" + ($env:APPVEYOR_REPO_COMMIT).Substring(0, 8)

Add-AppveyorMessage -Message "Patched File Version: $AssemblyFileVersion"
Add-AppveyorMessage -Message "Patched Informational Version: $AssemblyInformationalVersion"

$fileVersion = 'AssemblyFileVersion("' + $AssemblyFileVersion + '")';
$informationalVersion = 'AssemblyInformationalVersion("' + $AssemblyInformationalVersion + '")';

$foundFiles = get-childitem .\*AssemblyInfo.cs -recurse  
foreach( $file in $foundFiles )  
{
	if ($file.Name -eq $globalAssemblyFile)
	{
		#Don't patch the global info.
		continue;
	}

	$content = Get-Content "$file"
	
	Add-AppveyorMessage -Message "Patching $file"
	
	$afv = $fileVersion
	$aiv = $informationalVersion
	
	$hasFileAssemblyVersion = "'"+$content+"'" -match 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'

	if ($hasFileAssemblyVersion)
	{
		$assemblyVersionFormattedCorrectly = $matches[0] -match "(?<major>[0-9]+)\.(?<minor>[0-9])+(\.(?<build>([0-9])))?(\.(?<revision>([0-9])))?"

		if ($assemblyVersionFormattedCorrectly) 
		{
			$fileMajor=$matches['major'] -as [int]
			$fileMinor=$matches['minor'] -as [int]	
			$fileBuild=$matches['build'] -as [int]
			$fileRevision=$matches['revision'] -as [int]	
			
			
			$afv = "$fileMajor.$fileMinor.$env:APPVEYOR_BUILD_NUMBER"
			$aiv = "$afv-$env:APPVEYOR_REPO_SCM" + ($env:APPVEYOR_REPO_COMMIT).Substring(0, 8)
			
			Add-AppveyorMessage -Message "•	Specific AssemblyVersion found, using that instead: $fileMajor.$fileMinor.$fileBuild.$fileRevision ."
			Add-AppveyorMessage -Message "	○	Patched File Version: $afv"
			Add-AppveyorMessage -Message "	○	Patched Informational Version: $aiv"
			
			$afv = 'AssemblyFileVersion("' + $afv + '")';
			$aiv = 'AssemblyInformationalVersion("' + $aiv + '")';
		}
		else
		{
			Add-AppveyorMessage -Message "• Specific AssemblyVersion found, but it's not formatted correctly, skipping."
		}
	}
	
	$content -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $afv `
			 -replace 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $aiv | Set-Content "$file"
}
