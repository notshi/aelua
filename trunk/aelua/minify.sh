
cd mods/base/js
cat jquery.indent-1.0.js jquery-wet.js > all.js
cd ../../..

java -jar class/yuicompressor-2.4.2.jar --nomunge -o mods/base/js/all.min.js mods/base/js/all.js 

