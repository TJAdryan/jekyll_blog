---
layout: post
title: "Identifying Microsoft Teams Storage Usage with Python and Graph API"
date: YYYY-MM-DD HH:MM:SS -0000 # Adjust to your date
categories: python microsoft-graph teams admin
---

I usually have a hard time learning something when the information is completely abstarct, but many times I have had to help identify who is over consuming resources. Also I am going to use synchronous and Async code in the same script. I am going to use the Microsoft Graph API to get a list of all the teams in my organization and then get the storage usage for each team.  So hopefully someone will find this useful too.

## Prerequisites

Before starting, ensure you have the following:

* Python 3.7+
* The following Python libraries: `requests`, `msal`, `pandas`, `aiohttp`, `nest_asyncio`. Install them via pip:
    ```bash
    pip install requests msal pandas aiohttp nest_asyncio
    ```
* An Azure Active Directory (Azure AD) application registration with:
    * Client ID
    * Tenant ID
    * A generated Client Secret
    * The following Microsoft Graph API **Application Permissions** (admin consent granted):
        * `Group.Read.All` (to list Teams)
        * `Sites.Read.All` (to access drive storage information)

**Security Note:** Securely manage your `client_secret`. Avoid hardcoding it in scripts for production environments. Consider using environment variables or a service like Azure Key Vault.

## Python Script Walkthrough

### Part 1: Authentication with MSAL

We use the Microsoft Authentication Library (MSAL) for Python to obtain an access token for the Graph API.

```python
import json
import requests
from msal import ConfidentialClientApplication
import pandas as pd
from datetime import datetime,timedelta
import time
from time import sleep # Optional for deliberate delays

# --- Credentials - Replace with your actual values ---
client_id = 'YOUR_CLIENT_ID'
tenant_id = 'YOUR_TENANT_ID'
client_secret = 'YOUR_CLIENT_SECRET'
# --- End Credentials ---

msal_authority = f"[https://login.microsoftonline.com/](https://login.microsoftonline.com/){tenant_id}"
msal_scope = ["[https://graph.microsoft.com/.default](https://graph.microsoft.com/.default)"]

msal_app = ConfidentialClientApplication(
    client_id=client_id,
    client_credential=client_secret,
    authority=msal_authority,
)

def update_headers(current_msal_app, current_msal_scope):
    """Acquires a Graph API token and returns request headers."""
    result = current_msal_app.acquire_token_silent(
        scopes=current_msal_scope,
        account=None,
    )

    if not result:
        # print("No token in cache, acquiring new token for client...") # Optional logging
        result = current_msal_app.acquire_token_for_client(scopes=current_msal_scope)

    if "access_token" in result:
        access_token = result["access_token"]
        # print('Token acquired successfully.') # Optional logging
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        return headers
    else:
        error_description = result.get("error_description", "No error description provided.")
        print(f"Error acquiring token: {error_description}")
        raise Exception("No Access Token found or error in acquiring token.")

# Get initial headers
headers = update_headers(msal_app, msal_scope)
# print(f"Initial headers obtained at: {time.strftime('%X %x %Z')}") # 

The update_headers function handles token acquisition.

##Part 2: Fetching All Microsoft Teams
Teams are Microsoft 365 Groups with a 'Team' resource. We query the Graph API for these groups.

teams_url = "[https://graph.microsoft.com/v1.0/groups?$filter=resourceProvisioningOptions/Any(x:x](https://graph.microsoft.com/v1.0/groups?$filter=resourceProvisioningOptions/Any(x:x) eq 'Team')&$select=id,displayName"

print("\nFetching list of all Teams...")
start_fetch_teams_time = time.time()

all_teams_list = []
current_url = teams_url

while current_url:
    response = requests.get(current_url, headers=headers)
    response.raise_for_status() 
    teams_data = response.json()
    
    all_teams_list.extend(teams_data['value'])
    current_url = teams_data.get('@odata.nextLink', None) 
    # if current_url: # Optional logging
    #     print(f"Fetching next page of teams...")

df_teams = pd.DataFrame(all_teams_list)
df_unique_teams = df_teams.drop_duplicates(subset=['id'], keep='first')

end_fetch_teams_time = time.time()
elapsed_fetch_teams_time = end_fetch_teams_time - start_fetch_teams_time

print(f"\nFound {df_unique_teams.shape[0]} unique Teams.")
print(f"Time to fetch Teams list: {elapsed_fetch_teams_time:.2f} seconds")

team_ids_list = df_unique_teams['id'].tolist()
team_names_list = df_unique_teams['displayName'].tolist()

teams_url = "[https://graph.microsoft.com/v1.0/groups?$filter=resourceProvisioningOptions/Any(x:x](https://graph.microsoft.com/v1.0/groups?$filter=resourceProvisioningOptions/Any(x:x) eq 'Team')&$select=id,displayName"

print("\nFetching list of all Teams...")
start_fetch_teams_time = time.time()

all_teams_list = []
current_url = teams_url

while current_url:
    response = requests.get(current_url, headers=headers)
    response.raise_for_status() 
    teams_data = response.json()
    
    all_teams_list.extend(teams_data['value'])
    current_url = teams_data.get('@odata.nextLink', None) 
    # if current_url: # Optional logging
    #     print(f"Fetching next page of teams...")

df_teams = pd.DataFrame(all_teams_list)
df_unique_teams = df_teams.drop_duplicates(subset=['id'], keep='first')

end_fetch_teams_time = time.time()
elapsed_fetch_teams_time = end_fetch_teams_time - start_fetch_teams_time

print(f"\nFound {df_unique_teams.shape[0]} unique Teams.")
print(f"Time to fetch Teams list: {elapsed_fetch_teams_time:.2f} seconds")

team_ids_list = df_unique_teams['id'].tolist()
team_names_list = df_unique_teams['displayName'].tolist()

Part 3: Fetching Drive Storage (Synchronous Method)
This initial approach fetches storage information for each Team sequentially. It can be slow for many teams.

print("\nFetching drive storage for each team (Synchronous approach)...")
sync_start_time = time.time()

all_teams_drive_data_sync = []
# Consider token refresh strategy for very long running synchronous operations.
# headers = update_headers(msal_app, msal_scope) 

for i, teamid in enumerate(team_ids_list):
    if i > 0 and i % 50 == 0: # Progress indicator, skip first
        print(f"Processing team {i+1}/{len(team_ids_list)}: {team_names_list[i]}")
    
    drive_url = f'[https://graph.microsoft.com/v1.0/groups/](https://graph.microsoft.com/v1.0/groups/){teamid}/drive'
    
    try:
        response = requests.get(drive_url, headers=headers)
        response.raise_for_status()
        drive_info = response.json()
        
        team_frame = pd.json_normalize(drive_info)
        team_frame['team_id'] = teamid
        team_frame['teamName'] = team_names_list[i]
        all_teams_drive_data_sync.append(team_frame)
    except requests.exceptions.HTTPError as e:
        print(f"Error fetching drive for team ID {teamid} ({team_names_list[i]}): {e.response.status_code}")
    except json.JSONDecodeError:
        print(f"Error decoding JSON for team ID {teamid} ({team_names_list[i]})")
    except Exception as e:
        print(f"An unexpected error for team ID {teamid} ({team_names_list[i]}): {e}")
    
    # time.sleep(0.05) # Optional small delay for very basic throttling avoidance

if all_teams_drive_data_sync:
    space_teams_sync_df = pd.concat(all_teams_drive_data_sync, ignore_index=True)
    print(f"\nSynchronous fetching processed {len(space_teams_sync_df)} team drives.")
else:
    print("\nNo drive data fetched synchronously.")
    space_teams_sync_df = pd.DataFrame()

sync_end_time = time.time()
sync_elapsed_time = sync_end_time - sync_start_time
print(f"Execution time for synchronous drive fetching: {sync_elapsed_time:.2f} seconds")
# print(space_teams_sync_df.head() if not space_teams_sync_df.empty else "No sync data to show.")

Part 4: Asynchronous Data Fetching with aiohttp
To improve performance, we use aiohttp and asyncio for concurrent API calls.
import asyncio
import aiohttp
import nest_asyncio 

nest_asyncio.apply() 

async def fetch_drive_async(session, teamid, team_name, auth_headers):
    """Asynchronously fetches drive information for a single team."""
    drive_url = f'[https://graph.microsoft.com/v1.0/groups/](https://graph.microsoft.com/v1.0/groups/){teamid}/drive'
    try:
        async with session.get(drive_url, headers=auth_headers) as response:
            if response.status == 200:
                data = await response.json()
                if 'quota' in data and 'used' in data['quota']:
                    team_frame = pd.json_normalize(data)
                    team_frame['team_id'] = teamid
                    team_frame['teamName'] = team_name
                    return team_frame
                else:
                    # print(f"Warning: 'quota.used' not found for team {team_name} ({teamid}).") # Optional
                    return pd.DataFrame({'team_id': [teamid], 'teamName': [team_name], 'quota.used': [None], 'error_detail': ['Missing quota info']})
            else:
                # print(f"Error (async) for team {team_name} ({teamid}): {response.status}") # Optional
                return pd.DataFrame({'team_id': [teamid], 'teamName': [team_name], 'error_status': [response.status]})
    except Exception as e:
        # print(f"Exception (async) for team {team_name} ({teamid}): {e}") # Optional
        return pd.DataFrame({'team_id': [teamid], 'teamName': [team_name], 'exception': [str(e)]})

async def main_async_fetch(team_ids, team_names_list_async, auth_headers):
    """Main async function to gather drive information for all teams."""
    all_teams_data = []
    # For very large tenants, consider an asyncio.Semaphore to limit concurrency:
    # sem = asyncio.Semaphore(10) # Limit to 10 concurrent requests
    # async with sem:
    #     tasks.append(fetch_drive_async(session, teamid, team_names_list_async[i], auth_headers))

    async with aiohttp.ClientSession() as session:
        tasks = []
        for i, teamid in enumerate(team_ids):
            if i > 0 and i % 50 == 0: # Progress indicator
                print(f"Queueing async fetch for team {i+1}/{len(team_ids)}: {team_names_list_async[i]}")
            tasks.append(fetch_drive_async(session, teamid, team_names_list_async[i], auth_headers))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for res in results:
            if isinstance(res, pd.DataFrame):
                all_teams_data.append(res)
            else: 
                print(f"A task failed with exception: {res}")
    
    return pd.concat(all_teams_data, ignore_index=True) if all_teams_data else pd.DataFrame()

print("\nFetching drive storage for each team (Asynchronous approach)...")
current_headers = update_headers(msal_app, msal_scope) # Refresh token

async_start_time = time.time()
space_teams_async_df = asyncio.run(main_async_fetch(team_ids_list, team_names_list, current_headers))
async_end_time = time.time()
async_elapsed_time = async_end_time - async_start_time

print(f"\nAsynchronous fetching complete.")
print(f"Execution time for asynchronous drive fetching: {async_elapsed_time:.2f} seconds")
# print(space_teams_async_df.head() if not space_teams_async_df.empty else "No async data to show.")