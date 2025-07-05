# deploy.ps1 content (focus on these lines)

param(
    [string]$GitHubPatToken
)

# ... (other git config lines) ...

# <<< THIS IS THE CRITICAL SECTION FOR THE URL FIX >>>
# Extract just the repository name from $(Build.Repository.Name)
# Example: if $(Build.Repository.Name) is "TJAdryan/jekyll_blog", this gets "jekyll_blog"
$justRepoName = (Split-Path -Leaf "$(Build.Repository.Name)") 

# Construct the correct GitHub URL using your GitHub username and the extracted repo name
# Replace 'TJAdryan' with your actual GitHub username/organization if it's different.
$gitRepoUrl = "https://x-access-token:$GitHubPatToken@github.com/TJAdryan/$justRepoName.git"

# Define the temporary path to clone into
$tempRepoPath = "temp_repo"

Write-Host "Cloning repository from $gitRepoUrl"
git clone $gitRepoUrl $tempRepoPath -ErrorAction Stop # Added -ErrorAction Stop to fail early

# ... (rest of the script) ...
# Navigate into the cloned repository
Set-Location $tempRepoPath

# Checkout the GitHub Pages branch. Create it if it doesn't exist.
git checkout $(githubPagesBranch) -Force

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

Write-Host "Pushing changes to GitHub Pages branch $(githubPagesBranch)"
git push origin $(githubPagesBranch)