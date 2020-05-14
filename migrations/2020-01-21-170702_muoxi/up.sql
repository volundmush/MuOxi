-- Not sure if Plugin table is useful just yet, but ported it anyways.
CREATE TABLE PluginName (
    id INT NOT NULL CHECK (id > 0),
    name varchar(64) NOT NULL,
    PRIMARY KEY(id)
);

-- This table stores the different Types of Entities that can exist.
-- Might do this differently - maybe store a string on the Entities table?
-- Make it super flexible that way?
CREATE TABLE Types (
    id INT NOT NULL CHECK (id > 0),
    name varchar(64) NOT NULL,
    PRIMARY KEY(id)
);

-- This core table exists to ensure database integrity for everything in the game.
-- An Entity is defined as "anything that can have components." Something conceived
-- of in-game as "one thing" might be comprised of multiple Entities "under the hood".
CREATE TABLE Entities (
    id UUID NOT NULL,
    type_id INT NOT NULL REFERENCES Types(id),
    PRIMARY KEY(id)
);

-- Some Entities are 'fixtures' provided by plugins and other game data definitions/assets.
-- These special Entities have Fixture components which provide a way to globally identify them
-- for the purpose/usage of building scripts.
CREATE TABLE Fixturespace (
    id INT NOT NULL CHECK (id > 0),
    name varchar(64) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE FixtureComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    fixture_space_id INT NOT NULL REFERENCES Fixturespace(id),
    fixture_key varchar(255) NOT NULL,
    UNIQUE(fixture_space_id, fixture_key)
);

-- Provided for indexing of NameComponents. Those which are Searchable
-- are largely used for Access Control Lists and global indexing.
CREATE TABLE Namespace (
    id INT NOT NULL CHECK (id > 0),
    name varchar(64) NOT NULL,
    searchable BOOLEAN NOT NULL,
    PRIMARY KEY(id)
);

-- Many things have Names. If those names are
CREATE TABLE NameComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    namespace_id INT NOT NULL REFERENCES Namespace(id),
    name varchar(64) NOT NULL,
    color_name varchar(128) NOT NULL
);

CREATE INDEX idx_namecomponent on NameComponent(namespace_id, name);

-- This table is specifically for Entities which are Accounts.
-- Not actually sure what a good datatype to use for password is, given hashing.
-- Going with 'text' to be safe for now.
CREATE TABLE AccountComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    password TEXT NOT NULL,
    email varchar(320) NOT NULL
);

-- Child Types are used to identify/separate 'kinds' of Entities that can be the 'children'
-- of another entity. Examples include 'Room' and 'Inventory.'
CREATE TABLE ChildType (
    id INT NOT NULL UNIQUE,
    name varchar(64),
    PRIMARY KEY(id)
);

-- As shown above, a ChildComponent marks this entity as being a 'child' of a parent Entity.
-- Exactly how this relation works can be arbitrary; however, each 'child' must have a unique
-- text identifier within the 'Parent/ChildType' namespace.
CREATE TABLE ChildComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    parent UUID NOT NULL REFERENCES Entities(id),
    child_type_id INT NOT NULL REFERENCES ChildType(id),
    child_key varchar(64) NOT NULL,
    UNIQUE(owner, child_type_id, child_key)
);

-- This marks an Entity as being 'inside' an Entity. That's probably being
-- inside a room, but it may mean other things like being inside an 'Inventory.'
CREATE TABLE EntityLocationComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    location UUID NOT NULL UNIQUE REFERENCES Entities(id)
);

-- An Entity might be equipped to an 'Inventory'. This keeps track of such.
-- What slots/layers are actually available should be handled by application logic.
CREATE TABLE EquipSlotComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    slot_key varchar(64) NOT NULL,
    slot_layer INT NOT NULL CHECK (slot_layer >= 0)
);

-- Entities might have a 3D position in... wherever they are. This tracks such.
-- You could also use this for 2D positions by just making Z always 0.
CREATE TABLE FloatPositionComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    x DOUBLE NOT NULL,
    y DOUBLE NOT NULL,
    z DOUBLE NOT NULL
);

CREATE TABLE IntPositionComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    x INT NOT NULL,
    y INT NOT NULL,
    z INT NOT NULL
);

-- This is for Entities which ARE PlayerCharacters.
CREATE TABLE PlayerCharacterComponent (
    id UUID NOT NULL UNIQUE REFERENCES Entities(id),
    account_id UUID NOT NULL REFERENCES Entities(id),
    -- how about a playtime duration?
    -- maybe a bool for whether the player character's active?
    -- creation date? I dunno.
);

CREATE TABLE ACLPermission (
    id INT NOT NULL,
    name varchar(64) NOT NULL UNIQUE,
    PRIMARY KEY(id)
);

CREATE TABLE ACLEntry (
    id BIGINT NOT NULL,
    resource UUID NOT NULL UNIQUE REFERENCES Entities(id),
    target UUID NOT NULL UNIQUE REFERENCES Entities(id),
    mode varchar(64) NOT NULL,
    deny BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(resource, target, mode, deny),
    PRIMARY KEY(id)
);

CREATE TABLE ACLLink (
    acl_id BIGINT NOT NULL REFERENCES ACLEntry(id),
    perm_id INT NOT NULL REFERENCES ACLPermission(id),
    UNIQUE(acl_id, perm_id)
);

CREATE TABLE Attributes (
    id BIGINT NOT NULL,
    owner UUID NOT NULL REFERENCES Entities(id),
    category varchar(64) NOT NULL,
    name varchar(64) NOT NULL,
    data JSON NOT NULL,
    PRIMARY KEY(id),
    UNIQUE(owner, category, name)
);