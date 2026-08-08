# PSScriptAnalyzer configuration.
#
# Rules are excluded here rather than suppressed inline so the reasoning lives
# in one reviewable place. Everything not listed is enforced at Error and
# Warning severity by .github/workflows/ci.yml.

@{
    Severity     = @('Error', 'Warning')

    ExcludeRules = @(
        # PSAvoidUsingWriteHost
        # These are console installers, not library modules. Their progress
        # output ("installed: output-styles/eli15.md") is the user-facing
        # product, and it must NOT go to the success stream: Update-SettingsFile
        # returns a path, and Write-Output inside these functions would merge
        # progress text into that return value. -List does use Write-Output,
        # precisely because it emits data rather than progress.
        'PSAvoidUsingWriteHost',

        # PSUseShouldProcessForStateChangingFunctions
        # The flagged functions are script-internal helpers, not exported
        # cmdlets; nothing can call them with -WhatIf. The script's own
        # contract is that running it installs things. Adding ShouldProcess
        # plumbing to private helpers would add ceremony without adding a
        # capability anyone can reach.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
