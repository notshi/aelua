
echo "This will apt-get install lua(5.1) and svn if needed and then checkout the latest version of yarn to the current directory, please read this script file to verify it isn't doing anything bad before running it and make sure you are inside a directory you wish to install yarn in before running. KTHXBYE"

type -P lua &>/dev/null || {
echo "installing lua using sudo apt-get"
sudo apt-get install lua5.1
}

type -P svn &>/dev/null || {
echo "installing svn using sudo apt-get"
sudo apt-get install subversion
}

echo "getting or updating yarn from google code"
svn checkout https://aelua.googlecode.com/svn/trunk/jslua/html/luac .

echo "you may now run ./yarnterm.sh to play"
