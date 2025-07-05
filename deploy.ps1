param(
    [string]$GitHubPatToken
)

# Set Git user for the commit
git config --global user.email "azure-devops@$(Build.Repository.Name).com"
git config --global user.name "Azure DevOps CD Pipeline"

# Construct the correct GitHub URL using your GitHub username and the extracted repo name
# Replace 'TJAdryan' with your actual GitHub username/organization if it's different.
$repoName = "$(Build.Repository.Name)"
$gitHubUsername = "TJAdryan"  # Replace with your actual GitHub username

# Check if the username is repeated in the repo name and remove if it is
if ($repoName.StartsWith("$gitHubUsername/$gitHubUsername")) {
    $repoName = $repoName.Substring($gitHubUsername.Length + 1)
}

$gitRepoUrl = "https://x-access-token:$GitHubPatToken@github.com/$gitHubUsername/$repoName.git"

# Define the temporary path to clone into
$tempRepoPath = "temp_repo"

Write-Host "Cloning repository from $gitRepoUrl"
git clone $gitRepoUrl $tempRepoPath -ErrorAction Stop # Added -ErrorAction Stop to fail early

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