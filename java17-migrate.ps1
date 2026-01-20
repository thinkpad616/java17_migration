# ----------------------------------------------
# Windows Rewrite Migration Script (PowerShell)
# ----------------------------------------------

Write-Host ""
Write-Host "=== Java 17 Migration - OpenRewrite Runner (Windows) ==="
Write-Host ""

# ----------------------------------------------
# Helper: Verify Java is available
# ----------------------------------------------
function Assert-Java {
    if (-not (Get-Command "java" -ErrorAction SilentlyContinue)) {
        Write-Host "`nERROR: Java is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Java 17 before running this script."
        exit 1
    }
}

# ----------------------------------------------
# Helper: Verify Maven is available
# ----------------------------------------------
function Assert-Maven {
    if (-not (Get-Command "mvn" -ErrorAction SilentlyContinue)) {
        Write-Host "`nERROR: Maven is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Install Maven and try again."
        exit 1
    }
}

# ----------------------------------------------
# Run the OpenRewrite migration
# ----------------------------------------------
function Run-Migration {

    Assert-Java
    Assert-Maven

    Write-Host "`nRunning OpenRewrite migration..." -ForegroundColor Cyan

    $target_version = "1.0.9"
    $rewrite_maven_plugin = "5.2.6"

    # Modules
    $all_modules = @(
        "org.openrewrite.recipes:rewrite-migrate-java:2.0.5",
        "org.openrewrite.recipes:rewrite-spring:5.0.5",
        "org.openrewrite.recipes:rewrite-testing-frameworks:2.0.6",
        "com.capitalone.dsd.identity:rewrite-modules:$target_version"
    ) -join ","

    # Recipes
    $all_recipes = @(
        "org.openrewrite.java.migrate.UpgradeToJava17",
        "org.openrewrite.java.spring.boot2.SpringBoot2Junit4to5Migration",
        "org.openrewrite.java.testing.junit5.UseMockitoExtension",
        "org.openrewrite.java.testing.mockito.MockitoJUnitRunnerSilentToExtension",
        "com.capitalone.dsd.identity.ConsumerIdentityJava17"
    ) -join ","

    Write-Host "`nExecuting Maven Rewrite Plugin..." -ForegroundColor Yellow

    $cmd = @(
        "mvn",
        "-ntp",
        "-U",
        "org.openrewrite.maven:rewrite-maven-plugin:$rewrite_maven_plugin:run",
        "-DactiveRecipes=`"$all_recipes`"",
        "-DactiveModules=`"$all_modules`""
    ) -join " "

    Write-Host "`nCommand:"
    Write-Host $cmd -ForegroundColor DarkGray

    Invoke-Expression $cmd

    Write-Host "`nMigration complete." -ForegroundColor Green

    # Write version file like mac version
    "17.0" | Out-File -Encoding ASCII .java-version

    Write-Host "`nUpdated .java-version file created."
}

# ----------------------------------------------
# MENU
# ----------------------------------------------
function Show-Menu {
    Write-Host ""
    Write-Host "Select an option:"
    Write-Host "1) Run Rewrite Migration"
    Write-Host "2) Quit"
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Enter choice"

    switch ($choice) {
        "1" { Run-Migration }
        "2" { exit }
        default { Write-Host "Invalid selection." -ForegroundColor Red }
    }

} while ($true)
