Welcome to the text_butler wiki!

# Objective
Textbutler is a GUI application that allows text to be filtered or manipulated.

The processing takes place in "buffers", the type of processing is specified in text form in a "command line".

The commands normally allow an input buffer and an output buffer to be specified.

There are predefined buffers, but additional buffers can be defined.

## Workflow Example
Three lines are entered in the "input" buffer:
<pre>Joe,2,usr
Ada,3,usr
Bob,1,Adm
</pre>
Enter in the command line:
<pre>filter what="adm"
</pre>
Meaning: Only lines containing "adm" should be output.

After clicking "Execute", the following appears in the buffer named "output":
<pre>Bob,1,adm
</pre>
In the command line is entered:
<pre>sort how="w3,n2" separator=","
</pre>
This means: Sort word by word, consider column 3, then column 2, whereby column 2 is to be sorted numerically ("n"), words are separated with ",".

After pressing "Execute", that appears in the buffer named "output":
<pre>Bob,1,adm
Joe,2,usr
Ada,3,usr
</pre>
Further examples can be found in the description of the individual commands.

# Demo website
The webapp is installed on GitHub: https://hamatoma.github.io/#/

# Installation
There are some precompiled packages ready for installation.
## Linux
There is a ready package for the architecture x86_64 (64-bit Intel/Amd):
<pre>
wget -O /tmp/Install.sh https://github.com/hamatoma/text_butler/tree/main/tools/x86_64/Install.sh
# this script contains all needed data. Though it can be "transported" by an USB stick and so on.
bash /tmp/Install.sh
</pre>
The installation is done in the directory <code>/usr/share/text_butler</code>.
There are two symbolic links:
* <code>/usr/bin/run_text_butler</code> to start the GUI version
* <code>/usr/bin/text_slave</code> to start the command line version

## Website
* Create a directory for the website.
* Fetch the archive website.tgz and unpack it in the directory.
* Run InstallWebsite.sh
<pre>
BASE=/home/html/www
DOMAIN=butler.huber.de
mkdir -p $BASE/$DOMAIN
cd $BASE/$DOMAIN
wget -O /tmp/Install.sh https://github.com/hamatoma/text_butler/tree/main/tools/website.tgz
unzip website.tgz && rm website.tgz
./InstallWebsite.sh $DOMAIN
</pre>
# Translation
* [[Einleitung]]



