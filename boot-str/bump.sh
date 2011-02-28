lua bump.lua
svn ci ..
ssh www-data@xixs.com "cd appengine;svn up;cd boot-str;make;cd ..;tail log.txt;exit"
