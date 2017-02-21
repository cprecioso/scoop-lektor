param($dir)
$dir = Resolve-Path $dir

function New-TemporaryDirectory {
    # http://stackoverflow.com/a/34559554
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Extract-Archive($file, $dest) {
    7z x (Resolve-Path $file) "-o$(Resolve-Path $dest)"
}

Write-Output "Looking for last version of virtualenv..."

$pkg = (New-Object System.Net.WebClient).DownloadString("https://pypi.python.org/pypi/virtualenv/json") | ConvertFrom-Json
$pkg.urls | ForEach-Object {
    if ($_.python_version -eq "source" ) {
        $url = $_.url
    }
}

$tmp = New-TemporaryDirectory

$tmp_compressed = Join-Path $tmp "compressed"
New-Item $tmp_compressed -ItemType Directory

Write-Output "Downloading virtualenv..."

$venv_tarball = Join-Path $tmp_compressed "venv.tar.gz"
(New-Object System.Net.WebClient).DownloadFile($url, $venv_tarball)

Write-Output "Downloaded!"
Write-Output "Extracting..."

Extract-Archive $venv_tarball $tmp_compressed
Extract-Archive (Join-Path $tmp_compressed "dist") $tmp
Remove-Item $tmp_compressed -Force -Recurse

Write-Output "Extracted!"

Get-ChildItem $tmp | ForEach-Object {
    $possible = Join-Path $_.FullName "virtualenv.py"
    if (Test-Path $possible) {
        $venv = Resolve-Path $possible
    }
}

Write-Output "Creating new virtualenv..."

python2 $venv $dir

Write-Output "Created!"
Write-Output "Installing Lektor..."

$pip = Join-Path -Resolve $dir "Scripts\pip.exe"
& $pip install --upgrade Lektor

Write-Output "Installed!"
Write-Output "Cleaning up..."

Remove-Item $tmp -Force -Recurse

Write-Output "Done! Have fun"
