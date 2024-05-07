/*
This SQL code is aimed at extracting information from the GitHub archive related to recent contributors and their contributions to repositories.

Here's a breakdown of what each part of the code does:

1. **Common Table Expressions (CTEs)**:
   - `recent_contributions`: This CTE selects data from the `github_events` table, filtering for 'PushEvent' type events that occurred within the last year. It counts the number of contributions made by each actor (user) to each repository during that time frame.
   - `recent_contributors`: This CTE selects data from the `github_events` table, filtering for 'PushEvent' type events that occurred within the last three years. It counts the number of unique contributors to each repository during that time frame.

2. **Main Query**:
   - The main query selects specific columns from the `github_events` table, including actor information, repository information, and the number of contributions made by each actor to each repository.
   - It joins the `github_events` table with the `recent_contributions` CTE based on actor information and repository information.
   - It also joins the `github_events` table with the `recent_contributors` CTE based on repository information.
   - Finally, it applies filters to only include rows where the number of contributions by an actor to a repository is greater than 10, and the number of contributors to the repository is greater than 1000.

Therefore, this is code is filtering the GitHub Archieve to generate a summary of unique contributors to python repositories meeting specific criteria:

1. **Contributions Criteria**:
   - Repositories with over 10 contributions made in the most recent year.
   - Repositories with at least 1000 contributors who contributed in the last 3 years.

2. **Columns for the Table**:
   - Contributor username
   - Location of the contributor
   - Name of the repository 
*/

WITH recent_contributions AS (
  SELECT
    github_events.actor_display_login,
    github_events.actor_login,
    github_events.actor_id,
    github_events.repo_name,
    github_events.repo_id,
    COUNT(*) AS contributions
  FROM
    github_events
  WHERE
    github_events.type = 'PushEvent'
    AND TO_DATE (github_events.created_at) >= DATEADD (YEAR, -1, CURRENT_DATE)
    AND github_events.language ILIKE 'Python'
  GROUP BY
    github_events.actor_display_login,
    github_events.actor_login,
    github_events.actor_id,
    github_events.repo_name,
    github_events.repo_id
),
recent_contributors AS (
  SELECT
    github_events.repo_name,
    github_events.repo_id,
    COUNT(DISTINCT github_events.actor_login) AS contributors
  FROM
    github_events
  WHERE
    github_events.type = 'PushEvent'
    AND TO_DATE (github_events.created_at) >= DATEADD (YEAR, -3, CURRENT_DATE)
    AND github_events.language ILIKE 'Python'
  GROUP BY
    github_events.repo_name,
    github_events.repo_id
)
SELECT
  github_events.actor_display_login,
  github_events.actor_login,
  github_events.actor_id AS user_id,
  github_events.repo_name,
  github_events.repo_id,
  recent_contributions.contributions
FROM
  github_events
  JOIN recent_contributions ON github_events.actor_display_login = recent_contributions.actor_display_login
  AND github_events.actor_login = recent_contributions.actor_login
  AND github_events.actor_id = recent_contributions.actor_id
  AND github_events.repo_name = recent_contributions.repo_name
  AND github_events.repo_id = recent_contributions.repo_id
  JOIN recent_contributors ON github_events.repo_name = recent_contributors.repo_name
  AND github_events.repo_id = recent_contributors.repo_id
WHERE
  recent_contributions.contributions > 10
  AND recent_contributors.contributors > 1000;
