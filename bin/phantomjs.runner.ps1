$ScriptName = $MyInvocation.MyCommand.Name
$OriginalPath = Get-Location

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

function DoParameterValidation {
    if ($args.Length -eq 0) {
        "Usage: $ScriptName path_to_runner.html"
        exit
    }
}

function CheckHasPhantomJS {
    $has_phantom = Get-Command phantomjs -ErrorAction SilentlyContinue
    if (-not $has_phantom) {
        "ERROR: phantomjs is not installed"
        "Please visit http://www.phantomjs.org/"
        exit
    }
}

function FixFilePaths {
    $files = @()
    foreach ($path in $args) {
        $path_name = $path.ToString()
        if ($path_name.StartsWith('http://') -or $path_name.StartsWith('https://')) {
            $files += $path_name
        } elseif ($file = Get-Item $path -ErrorAction SilentlyContinue) {
            $files += ('/' + $file.FullName.Replace('\', '/'))
        }
    }
    return $files
}

DoParameterValidation $args
CheckHasPhantomJS

$test_files = FixFilePaths $args
$script_dir = Get-ScriptDirectory

Set-Location $script_dir
Remove-Item -Force *.xml

Set-Location ..
if (Get-Command git -ErrorAction SilentlyContinue) {
    git submodule update --init
}

Set-Location $script_dir
phantomjs "$script_dir\phantomjs-testrunner.js" $test_files

Set-Location $OriginalPath
