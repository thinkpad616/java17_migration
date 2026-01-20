# ===============================================================
# Windows Java 17 Migration Script (OpenRewrite)
# Includes:
#   - Java 17 migration
#   - JUnit migration (JUnit 4 → 5)
#   - Mockito migration
# Excludes:
#   - Spring recipes
#   - jenv or Java installers
# ===============================================================

Write-Host ""
Write-Host "=== Java 17 Migration (OpenRewrite) ==="
Write-Host ""

# ---------------------------------------------------------------
# Helper: Ensure Java is installed
# ---------------------------------------------------------------
function Assert-Java {
    if (-not (Get-Command "java" -ErrorAction SilentlyContinue)) {
        Write-Host "`nERROR: Java is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Java 17 manually and try again."
        exit 1
    }
}

# ---------------------------------------------------------------
# Helper: Ensure Maven is installed
# ---------------------------------------------------------------
function Assert-Maven {
    if (-not (Get-Command "mvn" -ErrorAction SilentlyContinue)) {
        Write-Host "`nERROR: Maven is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Install Maven manually and try again."
        exit 1
    }
}

# ---------------------------------------------------------------
# Run the OpenRewrite migration
# ---------------------------------------------------------------
function Run-Migration {

    Assert-Java
    Assert-Maven

    Write-Host "`nRunning OpenRewrite migration..." -ForegroundColor Cyan

    $rewritePluginVersion = "5.2.6"

    $modules = @(
        "org.openrewrite.recipes:rewrite-migrate-java:2.0.5",
        "org.openrewrite.recipes:rewrite-testing-frameworks:2.0.6"
    ) -join ","

    # -----------------------------------------------------------
    # RECIPES — ONLY Java 17, JUnit, Mockito
    # -----------------------------------------------------------
    $recipes = @(
        "org.openrewrite.java.migrate.UpgradeToJava17",
        "org.openrewrite.java.testing.junit5.JUnit5BestPractices",
        "org.openrewrite.java.testing.junit5.UseMockitoExtension",
        "org.openrewrite.java.testing.mockito.MockitoJUnitRunnerSilentToExtension"
    ) -join ","

    Write-Host "`nExecuting Maven Rewrite Plugin..." -ForegroundColor Yellow

    $cmd = @(
        "mvn",
        "-ntp",
        "-U",
        "org.openrewrite.maven:rewrite-maven-plugin:$rewritePluginVersion:run",
        "-DactiveRecipes=`"$recipes`"",
        "-DactiveModules=`"$modules`""
    ) -join " "

    Write-Host "`nCommand:"
    Write-Host $cmd -ForegroundColor DarkGray

    Invoke-Expression $cmd

    Write-Host "`nMigration complete!" -ForegroundColor Green

    # optional: create .java-version file (for consistency with mac script)
    "17.0" | Out-File -Encoding ASCII .java-version

    Write-Host "`nCreated .java-version = 17.0"
}

# ---------------------------------------------------------------
# Menu UI
# ---------------------------------------------------------------
function Show-Menu {
    Write-Host ""
    Write-Host "Select an option:"
    Write-Host "1) Run Java 17 Migration"
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
