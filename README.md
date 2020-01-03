# ![muoxi_logo][logo] 
# MuOxi MUD/MU* Rustic Game Engine v0.1.0
[![Build Status][travisimg]][travislink] 

*MuOxi* is a modern library for creating [online multiplayer text
games][wikimudpage] (MU* family) in Rust using the powerful and flexible [Amethyst][amethyst] game engine and backed by [Tokio][tokio] and [MongoDB][mongodb],. 
It allows developers and coders to design and flesh out their worlds in a
fast, safe, and reliable language. MuOxi engine is made available under *GPL3*. Join us on [discord][discord].


## Current Status

The codebase is currently in *alpha* stage . Majority of development is done on the `dev` 
branch, with occasional PRs to the main branch. There is a working TCP server that allows
for multiple connections and handles them accordingly. Effort is focused at the moment in 
designing the backend database structure using a combination of MongoDB and json files.

## Contributions

Any contributions from the community is appreciated and wanted! No matter your skill level any sort
of effort into this project is extremely welcomed. For those wanting to contribute, fork the `dev` branch
and submit PR's. Any questions or information, we welcome you at our [discord][discord] server. Come on by.

## Road Map

The bare minimum TODO features that must be implemented before I would consider it a bare mud game engine.

* Allows for multiple communication protocols (*telnet, MCCP, websocket, etc*)
* Allows for new player creation
* Asks for a name and password
* saves player info (etc. name, password)
* Implements some basic commands: quit, say, tell, shutdown
* ~~Handles players disconnecting or quitting~~
* Implements a periodic message every *n* seconds
* Implements some rudimentary admin control (eg. muting another player)
* Basic cardinal movement
* Implements a storage based system

## Database Design Architecture

The database design is seperated into three different layers, with different levels of abstraction.
MuOxi utilizes [MongoDB][mongodb] for its storage needs. A unique design approach has been taken that allows information 
to be kept safe from database corruption, brownouts, or blackouts. The ideology is
as follows:

```
 Layer 1: JSON Files <---
              |         |
             \ /        |
 Layer 2: MongoDB       |
              |         |
             \ /        |
 Layer 3: Cache/Memory --
```

#### Layer 1: Flat Files

The entire database actually lives in JSON files from accounts, mobs, players, equipment, spells, skills, etc... 
JSON files where chosen because of its close relationship with MongoDB native storage choice, [BSON][bson]; as well
as it's human friendly format. A seperate process called the *watchdog* monitors custom defined `.json` files in the 
`/config` directory for any changes to contents themselves. Upon a detected change it triggers an upload piece of logic
that *updates* [MongoDB][mongodb], which leads us to layer 2 of the design.


#### Layer 2: MongoDB

This is where all persistent data will live throughout, and past, the life-span of MuOxi. [MongoDB][mongodb] naturally
stores data in a [BSON][bson] format, and allows all the goodies that come with any database *(indexing, search, upsert, insert, deletion)*
The database should always be a reflection of what is stored in the flat files, when MuOxi uses data from the database, it gets loaded 
and we move to layer 3 of the design.

#### Layer 3: In-Memory

This is the layer where MuOxi will actually use all persistent and non-persistent data to drive the actual engine itself. Whether it be
handling different states of connected clients, combat data, player information, and any-and-all other memory will be read from the database
to keep the engine running. Upon an action within MuOxi that would causes a change to the Database, MuOxi will actually write to the flat-files
instead of directly to Mongo. This was a throughouly thought out process to keep MongoDB a read-only database, from the perspective of the engine itself.
When a change occurs and MuOxi writes to the flat files we began again at layer 1 of the design. __It is the responsibility of the WatchDog to monitor changes to
the json files and update MongoDB. MongoDB and the JSON files should always be a reflection of each other.__

## Core Design Architecture

The prototype idea of how the core design is laid out into three seperate objects.
1. Staging/Proxy Server *(Clients will connect to this server and essentially communicate with the engine via this stage)*
2. Game Engine *(all the game logic lies here and reacts to input from connected clients)*
3. Database *(stores information about entities, objects, and game data)* 
4. Communication *( Each supported comm client (MCCP, telnet, websocket) will act as a full-duplex proxy that communicates with the Staging Server)*

The idea is that players will connect via one of the supported communication protocols to the *proxy server*. In this server, clients 
are not actually connected to the game, unless they explicity enter. The *staging area* holds all connected client information such as 
player accounts, different characters for each player, and general settings. When a client acutally connects to the game itself
the server acts as a proxy that relays information from players to the game engine, where the engine will then react to the players input. 
The engine and staging area will be seperated and communicate via a standard TCP server. The reason for this seperation, is to protect players from completely
disconnecting from the game if changes to the game engine is made.

The support for multiple type of connections is a must. Therefore the following shows an example design layout that
has the ability to handle multiple communication protocols. Each comm type will have a unique port that must be addressed
and acts like a proxy to the main Staging Area.

```
------------
| Websocket | <---------------- \
------------                     \
----------                        ---------------------             ---------------
| Telnet | ---------------------->|Proxy/Staging Area | <-- TCP --> | Game Engine |
----------                        ---------------------             ---------------
                                 /
--------                        /
| MCCP | <----------------------
--------
```

This design is still in prototype phase.

## Features and Philosophy

The MuOxi library is aimed at creating a very simplistic and robust library for developers
to experiment and create online text adventure games. 
As it stands the engine has the following capabilities:

* Accepts multiple connections from players
* Maintains a list of connected players
* Hold shared states between connected clients
* Removes clients upon disconnection


## Quick Start Guide

The project contains two seperate bin that can both be evoked from the command line:

* *(Not working as intended at the moment)* cargo run --bin muoxi_web
    * Starts the websocket server listening for incoming webclients, *default 8001*

* cargo run --bin muoxi_staging
    * starts the main Proxy Staging server where all clients will *live*, this area is where clients will communicate to the game engine. Direct telnet clients can connect this is server via port *8000*

* cargo run --bin muoxi_watchdog
  * starts the external process that monitors changes to configuration json files. Once a change has been detected it triggers an update protocol to update MongoDB

* cargo run --bin muoxi_engine
    * Starts the main game engine running in it's own seperate process. The whole game is contained
    within a TCP listening server that exchanges information back and forth between to the Proxy Server. *Right now it is just an echo server*




## Future/Vision

The concept around MuOxi is not just to recreate an existing MUD game engine in Rust,
but rather to utilize the performance and safety that Rust has to offer. That being said, 
this future vision for MuOxi will change over time, but it needs to fulfill some features
that I think will make this an outstanding project.

1) The Core of MuOxi will be written in Rust, expanding the core will need Rust code
2) The game logic, that handles how Mobs interact, expiermental mob AI integration, etc..
   will be handled in Python.
3) *add more here*






[logo]: https://github.com/duysqubix/MuOxi/blob/master/.media/cog.png
[travisimg]: https://travis-ci.org/duysqubix/MuOxi.svg?branch=master
[travislink]: https://travis-ci.org/duysqubix/MuOxi
[wikimudpage]: http://en.wikipedia.org/wiki/MUD
[amethyst]: https://amethyst.rs/
[discord]: https://discord.gg/pMnBmGv
[tokio]: https://github.com/tokio-rs/tokio
[mongodb]: https://www.mongodb.com/
[bson]: http://bsonspec.org/