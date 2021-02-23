
$main_config_file = "docToolchainConfig.groovy"
# $version=ng
$version = "ng"
$distribution_url = "https://github.com/docToolchain/docToolchain/archive/v$version.zip"

$dtc_opts="$dtc_opts -PmainConfigFile=$main_config_file --warning-mode=none"

# https://docs.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables
# TODO: Check what's the best local installation directory in Win:
$home_path = $env:USERPROFILE
$folder_name = ".doctoolchain"
$dtcw_path = "$home_path\$folder_name"
 
Write-Host "dtcw - docToolchain wrapper V0.11 (PS)"

if ($args.Count -lt 1) {
    # Help text adapted to Win/PS: /<command>.ps1
    Write-Warning @'
Usage: ./dtcw [option...] [task...]

You can use the same options and tasks as in underlying gradle.
Use "./dtcw.ps1 tasks --group doctoolchain" to see available tasks.
Use "local", "sdk" or "docker" as first argument to force the use of a local, sdkman or docker install.

Examples:

    Download and install arc42 Template:
    ./dtcw.ps1 downloadTemplate

    Generate PDF:
    ./dtcw.ps1 generatePDF

    Generate HTML:
    ./dtcw.ps1 generateHTML

    Publish HTML to Confluence:
    ./dtcw.ps1 publishToConfluence
    
    get more documentation at https://doctoolchain.github.io
'@
    exit 1
}

# check if CLI or docker are installed:
$cli = $docker = $exist_home =  $False

if (Get-Command java -ErrorAction SilentlyContinue) {    
    $java = $True
} else {    
    # Text adapted
    Write-Warning @'
docToolchain depends on java, but the java command couldn't be found to install java. 
Please, follow the next link and install java:
https://www.java.com/en/download/help/windows_manual_download.html
'@
    exit 1
}

if (Get-Command dooctoolchain -ErrorAction SilentlyContinue) {        
    Write-Host "docToolchain as CLI available"
    $cli = $True
}

if (Get-Command docker -ErrorAction SilentlyContinue) {        
    Write-Host "docker available"
    $docker = $True
}

if (Test-Path $dtcw_path) {
    Write-Host "dtcw folder exist: '$dtcw_path'"
    $exist_home = $True
}

switch ($args[0]) {
    "local" {
        Write-Host "force use of local install"
        $docker = $False
        $firstArgsIndex = 1   # << Shift first param        
    }
    "docker" {
        Write-Host "force use of docker"
        $cli = $exist_home = $False
        $firstArgsIndex = 1   # << Shift first param
    }
    default {
        $firstArgsIndex = 0   # << Use all params        
    }
}

$commandArgs = $args[$firstArgsIndex..$args.Count] -Join " "

if ($cli) {
    # Execute local
    $command = "doctoolchain . $commandArgs $DTC_OPTS"
}
elseif ($exist_home) {        
    $command = "$dtcw_path\docToolchain-$version\bin\doctoolchain . $commandArgs $DTC_OPTS"
}
elseif ($docker) {
    # Check Docker is running...
    if (-not (Invoke-Expression "docker ps")) {
        Write-Host "Docker does not seem to be running, run it first and retry"
        exit 1
    }
    # Write-Host "Docker is running :)"
    $docker_cmd = Get-Command docker
    Write-Host $docker_cmd
    # TODO: Review next line:                                     
    $command = "$docker_cmd run --rm -it --entrypoint /bin/bash -v ${PWD}:/project 'rdmueller/doctoolchain:$version' -c 'doctoolchain . $commandArgs $DTC_OPTS && exit'"
}
else {
    Write-Host "docToolchain not installed."

    $confirmation = Read-Host "Do you wish to install doctoolchain to '$dtcw_path\'? [Y/N]"
    if ($confirmation -eq 'y') {       
        # TODO: Hide outputs ?
        New-Item -Path $home_path -Name $folder_name -ItemType "directory" | Out-Null      
        Invoke-WebRequest $distribution_url -OutFile "$dtcw_path\source.zip"  
        Expand-Archive -LiteralPath "$dtcw_path\source.zip" -DestinationPath "$dtcw_path\"
        # Remove-Item "$dtcw_path\source.zip"     #  << Remove .zip ?        
        $command = "$dtcw_path\docToolchain-$version\bin\doctoolchain . $commandArgs $DTC_OPTS"        
    } else {
        Write-Warning @'
>> TODO REVIEW:
you need docToolchain as CLI-Tool installed or docker."
to install docToolchain as CLI-Tool, please install...
'@
        exit 1
    }
}

Write-Host "Command to invoke: '$command'" # << line for debugging
Invoke-Expression "cmd /c $command"
