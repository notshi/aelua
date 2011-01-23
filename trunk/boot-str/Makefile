
all: bake

bake:
	ant
	
clean:
	ant clean
	
serv: bake
	../appengine-java-sdk/bin/dev_appserver.sh .war

upload: bake
	../appengine-java-sdk/bin/appcfg.sh update .war

