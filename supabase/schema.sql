-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Problems table
create table problems (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  statement text not null,
  target_audience text not null,
  time_spent_score int not null check (time_spent_score between 1 and 5),
  complaint_frequency_score int not null check (complaint_frequency_score between 1 and 5),
  pays_for_alternative boolean not null default false,
  willingness_to_pay_score int not null check (willingness_to_pay_score between 1 and 5),
  pain_score int generated always as (
    time_spent_score + complaint_frequency_score + willingness_to_pay_score +
    (case when pays_for_alternative then 5 else 0 end)
  ) stored,
  evidence_summary text,
  status text not null default 'Logged' check (status in ('Logged', 'Worth Pursuing', 'Not Worth It', 'Archived')),
  source text not null check (source in ('Interview', 'Observation', 'Research', 'Assumption')),
  notes text,
  created_at timestamptz not null default now()
);

-- Problem Evidence table
create table problem_evidence (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  problem_id uuid references problems on delete cascade not null,
  platform text not null check (platform in ('Trustpilot', 'G2', 'Reddit', 'Twitter/X', 'App Store Review', 'Google Play Review', 'Forum', 'Other')),
  quote text not null,
  url text,
  found_via text not null default 'Manual' check (found_via in ('Manual', 'AI Search')),
  created_at timestamptz not null default now()
);

-- Solutions table
create table solutions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  problem_id uuid references problems not null,
  statement text not null,
  feasibility_score int not null check (feasibility_score between 1 and 5),
  excitement_score int not null check (excitement_score between 1 and 5),
  is_chosen boolean not null default false,
  status text not null default 'Idea' check (status in ('Idea', 'Chosen', 'Validating', 'Validated', 'Killed', 'Building')),
  notes text,
  created_at timestamptz not null default now()
);

-- Validations table
create table validations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  solution_id uuid references solutions not null,
  method text not null check (method in ('Customer Interview', 'Fake Door', 'Prototype', 'Survey', 'Concierge', 'Pre-sale')),
  hypothesis text not null,
  success_signal text not null,
  result text not null default 'Not Run Yet' check (result in ('Not Run Yet', 'Passed', 'Failed', 'Inconclusive')),
  evidence text,
  date_run date,
  created_at timestamptz not null default now()
);

-- Row Level Security
alter table problems enable row level security;
alter table problem_evidence enable row level security;
alter table solutions enable row level security;
alter table validations enable row level security;

create policy "Users manage their own problems"
  on problems for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own problem evidence"
  on problem_evidence for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own solutions"
  on solutions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own validations"
  on validations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- User Settings table
CREATE TABLE IF NOT EXISTS user_settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null unique,
  gemini_api_key text,
  preferred_model text not null default 'gemini-3.5-flash',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table user_settings enable row level security;

create policy "Users manage their own settings"
  on user_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
