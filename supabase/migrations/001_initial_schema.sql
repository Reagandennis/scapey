-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
CREATE TYPE priority_enum AS ENUM ('low', 'medium', 'high');
CREATE TYPE mission_status_enum AS ENUM ('pending', 'active', 'complete');

-- Table: missions
CREATE TABLE missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    priority priority_enum DEFAULT 'medium',
    status mission_status_enum DEFAULT 'pending',
    estimated_minutes INT,
    planet_id UUID, -- References planets.id, added later in file
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: mission_subtasks
CREATE TABLE mission_subtasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_done BOOLEAN DEFAULT false,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: focus_sessions
CREATE TABLE focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    mission_id UUID REFERENCES missions(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ DEFAULT now(),
    ended_at TIMESTAMPTZ,
    duration_seconds INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: nebula_entries
CREATE TABLE nebula_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    raw_input TEXT NOT NULL,
    summary TEXT,
    steps JSONB,    -- Array of strings
    risks JSONB,    -- Array of strings
    timeline TEXT,
    revenue_model TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: galaxies
CREATE TABLE galaxies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: solar_systems
CREATE TABLE solar_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    galaxy_id UUID REFERENCES galaxies(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: planets
CREATE TABLE planets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    solar_system_id UUID REFERENCES solar_systems(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add foreign key reference from missions to planets
ALTER TABLE missions
ADD CONSTRAINT fk_planet
FOREIGN KEY (planet_id) REFERENCES planets(id) ON DELETE SET NULL;


-- Row Level Security (RLS) Policies

ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own missions"
ON missions FOR ALL USING (auth.uid() = user_id);

ALTER TABLE mission_subtasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own subtasks"
ON mission_subtasks FOR ALL USING (auth.uid() = user_id);

ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own focus sessions"
ON focus_sessions FOR ALL USING (auth.uid() = user_id);

ALTER TABLE nebula_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own nebula entries"
ON nebula_entries FOR ALL USING (auth.uid() = user_id);

ALTER TABLE galaxies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own galaxies"
ON galaxies FOR ALL USING (auth.uid() = user_id);

ALTER TABLE solar_systems ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own solar systems"
ON solar_systems FOR ALL USING (auth.uid() = user_id);

ALTER TABLE planets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own planets"
ON planets FOR ALL USING (auth.uid() = user_id);

-- Optional: auto-update updated_at on missions
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_missions_updated_at
BEFORE UPDATE ON missions
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();
