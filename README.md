# Supabase Free Project Keep-Alive with GitHub Actions

A small, transparent way for people using a **Supabase Free Plan** project who want to generate regular database activity automatically.

## Why does this exist?

Supabase Free projects may be paused after a period of
low activity. If you have a small personal project,
portfolio project, university project, or hobby application
that isn't used every day, this can become annoying.

This repository shows how to:

- create a harmless PostgreSQL keep-alive function
- expose it through the Supabase REST API
- test it with PowerShell
- call it automatically with GitHub Actions

> **Important:** Supabase says Free Plan projects may be paused after a period of low activity. Supabase's current documentation says that a few user database requests per day over the previous week are typically enough to keep a project from being paused. This project uses a GitHub Actions scheduled workflow to make a harmless API call to a PostgreSQL function in Supabase.
>
> This is **not an official Supabase anti-pause guarantee**. Supabase can change its inactivity rules, and this workflow should not be treated as a guarantee that a project will never be paused.

## What this project does

The flow is:

```text
GitHub Actions
      |
      | scheduled API request
      v
Supabase REST API
      |
      | POST /rpc/keep_alive
      v
PostgreSQL function
      |
      | SELECT 1
      v
Supabase database
```

The database function does not modify application data. It simply executes:

```sql
SELECT 1;
```

The GitHub workflow runs automatically on a schedule, so your computer does **not** need to stay on.

---

# Step 1 — Create the database function

Open your Supabase project and go to:

**SQL Editor → New query**

Copy the contents of:

```text
sql/keep_alive.sql
```

Paste it into the SQL Editor and click **Run**.

The function created is:

```sql
public.keep_alive()
```

It returns `1` after executing `SELECT 1`.

### Why a function?

The Supabase REST API exposes PostgreSQL functions through the `/rpc/<function_name>` endpoint. That lets GitHub Actions make a normal HTTPS request without needing direct access to the PostgreSQL connection.

---

# Step 2 — Test the function in Supabase

In Supabase SQL Editor, run:

```sql
select public.keep_alive();
```

Expected result:

```text
1
```

If you get `1`, the database function is working.

---

# Step 3 — Get your Supabase Project URL

In your Supabase dashboard, open:

**Project Settings → DATA API**

Find your **Project URL** .

It will look similar to:

```text
https://xxxxxxxxxxxx.supabase.co
```
NOTE: You will actually see **API URL**, Just remove **/rest/v1/** part from the URL.

You will use this as the `SUPABASE_URL` GitHub Secret.

---

# Step 4 — Get your Supabase Publishable/Anon key

On the API keys settings page under configuration, find the key intended for client-side/public API access.

Depending on the Supabase project/API version, this may appear as a newer **Publishable key** or the older **anon** key.

Use that key for this workflow.

## Never use a secret/service_role key here

Do **not** put a:

```text
service_role
```

key or other secret server-side key into this repository or into the workflow file.

The workflow only needs the public API key because the database function explicitly grants execution permission.

---

# Step 5 — Test the API from PowerShell

Before configuring GitHub Actions, test the exact API request locally.

Open PowerShell.

Set your values:

```powershell
$PROJECT_URL="https://YOUR_PROJECT_ID.supabase.co"
$SUPABASE_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```

Then run:

```powershell
Invoke-RestMethod `
  -Uri "$PROJECT_URL/rest/v1/rpc/keep_alive" `
  -Method Post `
  -Headers @{
    apikey=$SUPABASE_KEY
    Authorization="Bearer $SUPABASE_KEY"
  } `
  -ContentType "application/json" `
  -Body "{}"
```

Expected response:

```text
1
```

You can also use the ready-made script:

```text
scripts/test_keep_alive.ps1
```

---

# Step 6 — Create or choose a GitHub repository

You can put these files in:

- a dedicated repository such as `supabase-free-project-keepalive`, or
- an existing project repository.

For a public educational repository, a dedicated repository makes the purpose especially clear.

---

# Step 7 — Add GitHub Actions Secrets

Open your GitHub repository.

Go to:

**Settings → Secrets and variables → Actions**

Click:

**New repository secret**

Create:

### Secret 1

Name:

```text
SUPABASE_URL
```

Value:

```text
https://YOUR_PROJECT_ID.supabase.co
```

### Secret 2

Name:

```text
SUPABASE_KEY
```

Value:

```text
YOUR_PUBLISHABLE_OR_ANON_KEY
```

These values are stored by GitHub and are not written directly into the workflow file.

---

# Step 8 — Add the GitHub Actions workflow

Create this file:

```text
.github/workflows/supabase-keepalive.yml
```

The repository already includes this file.

The workflow contains:

```yaml
on:
  schedule:
    - cron: "17 0 * * *"
  workflow_dispatch:
```

The schedule runs once per day.

The `17` minute offset is intentional: GitHub notes that scheduled workflows can be delayed during periods of high load, especially around the start of an hour. Running at a non-zero minute can reduce the chance of competing with the top-of-hour load.

GitHub scheduled workflows use UTC unless a timezone is explicitly configured.

---

# Step 9 — Push the files to GitHub

If you're working locally:

```powershell
git add .
git commit -m "Add Supabase keep-alive workflow"
git push
```

Make sure the workflow file exists on the repository's **default branch**.

---

# Step 10 — Test the GitHub Action manually

You do **not** need to wait for the scheduled time.

Go to:

**GitHub → Actions → Supabase Keep Alive**

Click:

**Run workflow**

Then run it.

You should see a successful workflow run.

The workflow is also configured with:

```yaml
workflow_dispatch:
```

which provides the manual Run workflow button.

---

# Step 11 — Let GitHub run it automatically

After the manual test succeeds, you don't need to run it every day.

GitHub Actions will execute the workflow according to the schedule.

Your computer does not need to be running.

The workflow will:

```text
Every day
   ↓
GitHub starts a runner
   ↓
curl sends POST request
   ↓
Supabase REST API receives it
   ↓
keep_alive() executes
   ↓
SELECT 1
```

---

# Step 12 — Check the workflow occasionally

Open:

**GitHub → Actions → Supabase Keep Alive**

You can see whether recent runs succeeded or failed.

You should occasionally check this, especially if the repository is important.

---

# Step 13 — Understand the limitations

## 1. This is not an official Supabase guarantee

Supabase's documentation says Free projects may be paused after low activity over a 7-day period and says that a few user database requests per day are typically enough to avoid being considered inactive.

However, Supabase does not promise that this particular GitHub Actions setup will permanently prevent pausing.

If you need a guarantee against inactivity pausing, Supabase's paid plans do not pause projects for inactivity.

## 2. GitHub scheduled workflows have their own limitation

GitHub says scheduled workflows in public repositories are automatically disabled after **60 days with no repository activity**.

Therefore, a standalone public keep-alive repository should be checked periodically. If the workflow becomes disabled, re-enable it or make repository activity/changes as appropriate.

If you put this workflow in an actively developed project repository, this limitation is less likely to be a practical problem.

## 3. The workflow does not keep your computer running

GitHub provides the runner.

Your:

- PC
- VS Code
- Flutter app
- FastAPI server

do not need to be running for the scheduled workflow.

## 4. Do not commit secrets

Never put a private database password, service-role key, or other secret directly into:

```text
.yml
.sql
.ps1
README.md
```

Use GitHub Secrets instead.

---

# Troubleshooting

### `401 Unauthorized`

Check:

- `SUPABASE_URL`
- `SUPABASE_KEY`
- whether you copied the correct publishable/anon key

### `404 Not Found`

Check that the function is named exactly:

```text
public.keep_alive
```

and that the URL is:

```text
https://YOUR_PROJECT_ID.supabase.co/rest/v1/rpc/keep_alive
```

### `403` / permission error

Run the SQL in:

```text
sql/keep_alive.sql
```

again and confirm that the function has execute permission for the `anon` role.

### GitHub Action doesn't appear

Make sure the file is located exactly at:

```text
.github/workflows/supabase-keepalive.yml
```

and that it has been pushed to the repository's default branch.

---

# Why this approach?

There are several ways people discuss keeping a Supabase Free project active, including database-side scheduled jobs.

This repository deliberately uses:

```text
GitHub Actions
        ↓
Supabase REST API
        ↓
PostgreSQL function
```

because it makes the source of the activity explicit and uses an API request from outside the database itself.

It also gives users a visible execution history through GitHub Actions.

---

# Disclaimer

This repository is a community-maintained example, not an official Supabase project.

Supabase may change its Free Plan inactivity policy, API behavior, limits, or recommendations. Always check the current Supabase documentation before relying on this approach.

Official documentation:

- Supabase Project Pausing: https://supabase.com/docs/guides/platform/free-project-pausing
- Supabase Cron: https://supabase.com/docs/guides/cron
- GitHub Actions Workflows: https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows
- GitHub Scheduled Workflows: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
