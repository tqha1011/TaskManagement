## Database Schema

The database is built on **PostgreSQL** (hosted via Supabase) and is strictly secured using **Row Level Security (RLS)**.

### Database ERD

<img width="1247" height="620" alt="image" src="https://github.com/user-attachments/assets/30b4850d-744e-4c80-bcc8-d225be763d16" />


### Core Database Dictionary

| Table Name | Description / Purpose | Key Relationships & Security |
| :--- | :--- | :--- |
| **`profile`** | Extended data for Supabase users (username, avatar, timezone). | `1:1` with `auth.users`. |
| **`category`** | Life contexts or folders created by users (e.g., Work, Health). | Belongs to `profile` (RLS enforced). |
| **`task`** | The main entity containing to-do properties (title, status, priority). | Belongs to `profile` and `category`. |
| **`note`** | Satellite table for long-form text descriptions. | `1:N` with `task`. |
| **`subtask`** | Satellite table acting as a checklist inside a specific task. | `1:N` with `task`. |
| **`reminder`** | Scheduling entity for push notifications. | `1:N` with `task`. |

### Security Architecture
* **Row Level Security (RLS):** Every core table contains a `profile_id`. RLS policies are enforced at the database level so users can only `SELECT`, `INSERT`, `UPDATE`, or `DELETE` their own data.
