# Zielsetzung
Textbutler ist eine GUI-Applikation, die es erlaubt, Text zu filtern oder zu manipulieren.

Die Verarbeitung erfolgt in "Puffern", die Art der Verarbeitung wird in einer "Kommandozeile" in Textform angegeben.

Die Kommandos erlauben normalerweise die Angabe eines Eingabepuffers und eines Ausgabepuffer.

Es gibt vordefinierte Puffer, es können aber weitere Puffer definiert werden.

## Beispiel
Im Puffer "input" werden drei Zeilen eingetragen:
<pre>Joe,2,usr
Ada,3,usr
Bob,1,adm
</pre>
In der Kommandozeile wird eingetragen:
<pre>filter what="adm"
</pre>
Bedeutung: es sollen nur Zeilen, die "adm" enthalten, ausgegeben werden.

Nachdem auf "Execute" gedrückt wurde, erscheint im Puffer "output":
<pre>Bob,1,adm
</pre>
In der Komandozeile wird eingetragen (":
<pre>sort how="w3,n2" separator=","
</pre>
Das bedeutet: Sortiere wortweise, berücksichtige Spalte 3, danach Spalte 2, wobei Spalte 2 numerisch zu sortieren ist ("n"), Worte werden mit "," getrennt.

Nachdem auf "Execute" gedrückt wurde, erscheint im Puffer "output":
<pre>Bob,1,adm
Joe,2,usr
Ada,3,usr
</pre>
Weitere Beispiele sind bei der Beschreibung der einzelnen Kommandos vorhanden.

# Demo website
Die Webapplikation ist auf Github installiert: https://hamatoma.github.io/#/

# Installation
Es gibt einige kompilierte Pakete zur einfachen Installation:

## Linux
Es gibt ein fertiges Paket für die Architektur x86_64 (64-bit Intel/Amd):
<pre>
wget -O /tmp/Install.sh https://github.com/hamatoma/text_butler/tree/main/tools/x86_64/Install.sh
# this script contains all needed data. Though it can be "transported" by an USB stick and so on.
bash /tmp/Install.sh
</pre>
Die Installation erfolgt in das Verzeichnis <code>/usr/share/text_butler</code>.

Es gibt zwei symbolische Links:
* <code>/usr/bin/run_text_butler</code> Start der GUI-Applikation
* <code>/usr/bin/text_slave</code> Start der Kommandozeilenapplikation

## Webseite
* Erstelle ein Verzeichnis für die Webseite
* Laden das Archiv website.tgz herunter und entpacke es in diesem Verzeichnis
* Führe das Script InstallWebsite.sh aus
<pre>
BASE=/home/html/www
DOMAIN=butler.huber.de
mkdir -p $BASE/$DOMAIN
cd $BASE/$DOMAIN
wget -O /tmp/Install.sh https://github.com/hamatoma/text_butler/tree/main/tools/website.tgz
unzip website.tgz && rm website.tgz
./InstallWebsite.sh $DOMAIN
</pre>
# Übersetzung
* [[Home]]
