###No longer updated. Latest code https://bitbucket.org/xixs/pagecake

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

###ModChan - An image board / commenting system.

The most basic design of social web chit chat.

Intended to be used as a generic commenting system.

example -> http://wet.appspot.com/chan

source -> http://code.google.com/p/aelua/source/browse/#svn/trunk/aelua/mods/chan


###ModDice - Random numbers for gamers.

A simple dice throwing module.

It just rolls some dice.

An example of how to use the image library.

example -> http://wet.appspot.com/dice

source -> http://code.google.com/p/aelua/source/browse/#svn/trunk/aelua/mods/dice

If you would like more dice or alternative images, consider donating them yourself :) See http://code.google.com/p/aelua/source/browse/#svn/trunk/aelua/mods/dice/art/plain for examples of what we need.

It would be nice to knock up some blender projects and having a clean rendered option.


###ModWaka - A wiki like module.

Actually the .plan is to have slightly less of a wiki than normal.

No wiki markup, just named chunks of text.

If you want it pretty then use raw html, or html page templates that format waka text chunks.

The only special waka markup is links, a short link is any word beginning with a / for example

```
/page

//root/page

///domain.com/root/page
```

Which, if you remove the first "/" is a direct map to the way html anchor hrefs work if the remaining string was just inserted into it. Which is of course exactly what the waka code does.

No spaces allowed, spaces are evil, use _ or + or %20 if you need a space. %20 and maybe even + will map to an actual space in the url linked to but it is of course unsightly.

A long link is juat a normal formatted url, for instance.

http://domain.com/root/page

On top of this automatic client side sniffing of links and embedding of their content can be enabled. This turns any .png .jpg .gif into an embedded image. Or a youtube link into an embeded video. Or a polldaddy poll into a poll, and so on for whatever content links have been enabled by the site owner. This is rather powerful, simple, secure and a total hack.

Why not easily allow random words to link to anything? Because this is why you can't have nice things

If at anypoint you decide you need more functionality then just switch to html. Waka markup is intended to be simple yet usable it is not intended to do everything.

Personally I believe wikipedia to be pure evil, not because of citation needed but instead the perl like syntax that assaults the eyes of anyone foolish enough to click on edit. It is not a step up from html, so why bother with the added complexity?

###How to ModWaka
```
#name option is startchunk chunkname options.
```

There can be multiple options - an option is anything with = between them.

form=raw means use as is (default line break is ` <br/>` / turns returns into ` <br/>`).

trim=ends means remove all whitespace (enter/tab/space) at beginning or end of chunk (for eg. ` <h1> `title that comes with extra line height properties).

form=nohtml means no html in the chunk.

a space after # means that chunk is a sudochunk so it's not a real chunk, just for layout purposes, used as chunk definition (eg. a chunk with 50 options could have the options typed out for better legibility instead of all on one line).

```
## at the beginning becomes a comment.
```

to uncomment a comment/chunk (like above), just add a space before it.

a chunk will not show unless you include it in the body. you include it by using {}.

the default chunks are #plate(layout of page), #title and #body.

 #plate is the ONLY thing that gets displayed (it's your index.html). #title and #body are referenced inside #plate. 

```
#plate

hello world
```

typing the above will replace everything.


###ModThumbcache - an image resize and memcache bouncer.

A simple way of automagically providing cached thumbnails for any image.

Images are read, resized and then stored in memcache before being served.

Future requests are just served by memcache.

This is also an example of a simple memcache semaphore system.

http://code.google.com/p/aelua/source/browse/#svn/trunk/aelua/mods/thumbcache

for example

http://wet.appspot.com/thumbcache/16/16/code.google.com/p/aelua/logo

Generates a 16x16 image from the aelua project logo, please don't abuse that link. Just host your own copy of the example wet application.

#Apps
A list of available apps.

*Updated Jun 4, 2011 by KrissD*

Apps live in the root of the svn here http://code.google.com/p/aelua/source/browse/#svn/trunk/ and each also depends upon the contents of the aelua directory for basic functionality.

Apps are intended to be entire example sites you can configure to your tastes then deploy to appengine.

###AppWet - is the example aelua app.
http://wet.appspot.com/

http://code.google.com/p/aelua/source/browse/#svn/trunk/wet

###AppHoeHouse - is a hommage to the web game whore house.
http://hoe-house.appspot.com/

http://code.google.com/p/aelua/source/browse/#svn/trunk/hoe-house

###AppBootStrap - is a cunning plan
http://boot-strap.appspot.com/

http://code.google.com/p/aelua/source/browse/#svn/trunk/boot-strap

###AppShitProduct - is a future video documentary mashup kinda thing.
http://shit-product.appspot.com/

http://code.google.com/p/aelua/source/browse/#svn/trunk/shit-product
