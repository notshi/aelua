###No longer updated. Latest code lives at https://bitbucket.org/xixs/pagecake

Imported from the now defunct, https://code.google.com/p/aelua/

Archived - https://archive.today/GliE2

![aelua screenshot](http://wet.genes.pw/data/aelua_screen/aelua_screen.png)

Thanks, google :/

# aelua

Where the current focus is on using nginx as an alternative host to appengine.

The .plan for this project is to produce a lua web framework which is abstract enough that the lua code is compatible with appengine but not dependent upon it.

Right now this is all hacks, hacks that seem to work :)

See http://wet.appspot.com/ for a live example/test or http://hoe-house.appspot.com/ for something a bit more meaty.

http://boot-str.appspot.com/ contains an easy to install aelua server and documentation on all the aelua mods.

There is no attempt to provide any compatibility with kepler project lua servlets.

That said, one of my long term goals is to provide a standalone host, using the kepler project libraries as a replacement for appengine.

The lua (5.1) java core is provided by http://code.google.com/p/jillcode/

See [HowToBuild](#how-to-build) for clues on how to build. outofdate

See [Mods](#mods) for some example modules. outofdate

See [Apps](#apps) for some example apps. outofdate

Recently switched from SVN to HG so there maybe some issues and the older history will all be in the svn. Also note that the wiki here is now dead since the project is its own wiki. Find it at http://boot-str.appspot.com/

Be sure to use the extra repos as required in .hgsub otherwise you will not get very far.

http://code.google.com/p/aelua/source/browse/.hgsub

For a quick and dirty install into your own appengine instance goto http://boot-str.appspot.com/install


#How to build

How to build the provided code. 

*Updated Jun 4, 2011 by KrissD*

You will need to install a java environment / compiler and ant.

If you checkout https://aelua.googlecode.com/svn/trunk/

Then from within this directory you will find the aelua core in aelua, the java sdk in appengine-java-sdk and some example apps. The default aelua app running at http://wet.appspot.com/ can be found in the wet directory, this is a good place to start looking.

Inside each app directory the following is true:

There is a simple makefile setup with a handful of targets, running make assuming you have a development environment installed will work. Running ant will also work, the makefile is mostly just an ant wrapper.

make bake will create and build into a war dir.

make serv will run a local test server from this war dir.

Whilst the test server is running I have also been using make bake to refresh the lua files within the war. This seems to be working fine and makes testing updates very easy.

make upload deploys to appengine, you will need to change the application id in /html/WEB-INF/appengine-web.xml to tell it where to deploy.

Windows users are expected to install ant and make as well as the java dev kit. This is something of a separate problem.

to recap

install java sdk , svn and ant (and a make if you are on windows)

```
svn co https://aelua.googlecode.com/svn/trunk/ aelua
cd aelua
cd wet
make serv
you should now be serving the wet test app at localhost:8080
```

Please be aware that setting cookies on localhost is problematic. I like to set up a host.local domain to test on instead to get around this problem.


#Mods
A list of available modules.

*Updated Jun 4, 2011 by KrissD*

They live in the svn here http://code.google.com/p/aelua/source/browse/#svn/trunk/aelua/mods and each should be self contained.

The ant build copies the contents of the mods into the war root such that mods/dice/art ends up in /art/dice and so on for all directories in each provided mod.

ModChan

ModDice

ModWaka

ModThumbcache

#Apps
A list of available apps.

*Updated Jun 4, 2011 by KrissD*

Apps live in the root of the svn here http://code.google.com/p/aelua/source/browse/#svn/trunk/ and each also depends upon the contents of the aelua directory for basic functionality.

Apps are intended to be entire example sites you can configure to your tastes then deploy to appengine.

AppWet

AppHoeHouse

AppBootStrap

AppShitProduct
