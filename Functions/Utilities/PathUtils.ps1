function Get-BasePath {
    try {
        # Dynamically determine the base path
        $BasePath = $PSScriptRoot
        if (-not $BasePath) {
            $BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        return $BasePath
    } catch {
        throw "Unable to determine the base path: $($_.Exception.Message)"
    }
}