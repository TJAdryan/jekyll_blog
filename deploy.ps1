# deploy.ps1 content (focus on these lines)

param(
    [string]$GitHubPatToken
)

# Set Git user for the commit
git config --global user.email "azure-devops@$(Build.Repository.Name).com"
git config --global user.name "Azure DevOps CD Pipeline"

# Define the GitHub Pages branch
$gitHubPagesBranch = "$(githubPagesBranch)"

# Checkout the main branch
git checkout main

# Remove all existing files (except .git folder) to ensure a clean deploy.
Write-Host "Cleaning existing files in $(Get-Location)"
Get-ChildItem -Path . -Exclude ".git" -Recurse -Force | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
}

# Copy the newly built site files from the artifact download directory
Write-Host "Copying built site from $(Pipeline.Workspace)/$(artifactName) to $(Get-Location)"
Copy-Item -Path "$(Pipeline.Workspace)/$(artifactName)/*" -Destination "." -Recurse -Force

# Add all changes, commit, and push to the GitHub Pages branch
git add .
git commit -m "Azure DevOps CD: Deployed new blog content - $(Build.BuildId) [skip ci]" -ErrorAction SilentlyContinue

# Checkout the gh-pages branch
git checkout $gitHubPagesBranch

# Merge the changes from main into gh-pages
git merge main

Write-Host "Pushing changes to GitHub Pages branch $gitHubPagesBranch"
git push origin $gitHubPagesBranch