-- doomlauncher.sql
-- SQLite schema for a generic Doom source port launcher.
--
-- Conventions:
--   * names are english, lowercase, singular and snake_case
--   * primary keys are <entity>_id, INTEGER, autoincrement
--   * foreign keys are named <entity>_id and reference <entity>(<entity>_id)
--   * unique keys are set where a value must be unique (e.g. port name)
--
-- SQLite has foreign key enforcement disabled by default: it must be
-- enabled with PRAGMA foreign_keys = ON on every connection.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- port : configuration of a source port (GZDoom, ZDoom, Zandronum, ...)
-- ---------------------------------------------------------------------------

CREATE TABLE port (
    port_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT    NOT NULL,
    executable_path  TEXT    NOT NULL,
    parameter        TEXT,               -- default parameters for every launch
    UNIQUE (name)
);

-- ---------------------------------------------------------------------------
-- file : any file on the filesystem usable by a port (wad, pk3, deh, ...)
-- ---------------------------------------------------------------------------

CREATE TABLE file (
    file_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT    NOT NULL,
    path     TEXT    NOT NULL,
    UNIQUE (path)
);

-- ---------------------------------------------------------------------------
-- iwad : base game data (iwad, ipk3, ...), always loaded at position 0
-- ---------------------------------------------------------------------------

CREATE TABLE iwad (
    iwad_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT    NOT NULL,
    path     TEXT    NOT NULL,
    UNIQUE (path)
);

-- ---------------------------------------------------------------------------
-- profile : launch configuration with one port, one iwad, n ordered files
--           and optional extra parameters
-- ---------------------------------------------------------------------------

CREATE TABLE profile (
    profile_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    port_id     INTEGER NOT NULL REFERENCES port (port_id) ON DELETE RESTRICT,
    iwad_id     INTEGER NOT NULL REFERENCES iwad (iwad_id) ON DELETE RESTRICT,
    parameter   TEXT,                   -- extra parameters for this profile
    UNIQUE (name)
);

-- ---------------------------------------------------------------------------
-- profile_file : additional files of a profile with their load order;
--                the iwad is always at position 0 and is not stored here,
--                so load_order starts from 1
-- ---------------------------------------------------------------------------

CREATE TABLE profile_file (
    profile_id  INTEGER NOT NULL REFERENCES profile (profile_id) ON DELETE CASCADE,
    file_id     INTEGER NOT NULL REFERENCES file (file_id) ON DELETE CASCADE,
    load_order  INTEGER NOT NULL,
    PRIMARY KEY (profile_id, file_id),
    UNIQUE (profile_id, load_order),
    CHECK (load_order >= 1)
);

-- ---------------------------------------------------------------------------
-- dmflags : flag groups managed per port; name is the command line parameter
--           of the group (dmflags, dmflags2, zadmflags, zactorflags, ...)
-- ---------------------------------------------------------------------------

CREATE TABLE dmflags (
    dmflags_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    port_id      INTEGER NOT NULL REFERENCES port (port_id) ON DELETE CASCADE,
    name         TEXT    NOT NULL,
    description  TEXT,
    UNIQUE (port_id, name)
);

-- ---------------------------------------------------------------------------
-- dmflag : single flag of a group, a bit value with a meaning
-- ---------------------------------------------------------------------------

CREATE TABLE dmflag (
    dmflag_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    dmflags_id   INTEGER NOT NULL REFERENCES dmflags (dmflags_id) ON DELETE CASCADE,
    value        INTEGER NOT NULL,
    name         TEXT    NOT NULL,
    description  TEXT,
    UNIQUE (dmflags_id, value),
    UNIQUE (dmflags_id, name),
    CHECK (value <> 0)
);

-- ---------------------------------------------------------------------------
-- profile_dmflag : flags enabled in a profile; the value of a group is the
--                  bitwise OR of the flags selected for that group
-- ---------------------------------------------------------------------------

CREATE TABLE profile_dmflag (
    profile_id  INTEGER NOT NULL REFERENCES profile (profile_id) ON DELETE CASCADE,
    dmflag_id  INTEGER NOT NULL REFERENCES dmflag (dmflag_id) ON DELETE CASCADE,
    PRIMARY KEY (profile_id, dmflag_id)
);

-- foreign key indexes
CREATE INDEX idx_profile_port_id             ON profile (port_id);
CREATE INDEX idx_profile_iwad_id             ON profile (iwad_id);
CREATE INDEX idx_profile_file_file_id        ON profile_file (file_id);
CREATE INDEX idx_dmflags_port_id             ON dmflags (port_id);
CREATE INDEX idx_dmflag_dmflags_id           ON dmflag (dmflags_id);
CREATE INDEX idx_profile_dmflag_dmflag_id    ON profile_dmflag (dmflag_id);
