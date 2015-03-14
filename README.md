# aelua

The latest code for this project now lives at https://bitbucket.org/xixs/pagecake

Where the current focus is on using nginx as an alternative host to appengine.

The .plan for this project is to produce a lua web framework which is abstract enough that the lua code is compatible with appengine but not dependent upon it.

Right now this is all hacks, hacks that seem to work :)

See http://wet.appspot.com/ for a live example/test or http://hoe-house.appspot.com/ for something a bit more meaty.

http://boot-str.appspot.com/ contains an easy to install aelua server and documentation on all the aelua mods.

There is no attempt to provide any compatibility with kepler project lua servlets.

That said, one of my long term goals is to provide a standalone host, using the kepler project libraries as a replacement for appengine.

The lua (5.1) java core is provided by http://code.google.com/p/jillcode/

see HowToBuild for clues on how to build. outofdate

see Mods for some example modules. outofdate

see Apps for some example apps. outofdate

Recently switched from SVN to HG so there maybe some issues and the older history will all be in the svn. Also note that the wiki here is now dead since the project is its own wiki. Find it at http://boot-str.appspot.com/

Be sure to use the extra repos as required in .hgsub otherwise you will not get very far.

http://code.google.com/p/aelua/source/browse/.hgsub

For a quick and dirty install into your own appengine instance goto http://boot-str.appspot.com/install
