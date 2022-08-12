## [0.4.1] - 2022.08.12

* new command: insert
* fix: handling of Filters in command "sort"
* fix: handling of strings in "pattern" parameters: Escaping special chars.
* corrections in documentation

## [0.4.0] - 2022.08.06

new commands: sort reverse
* package lints replaces pedantic, additional warnings removed   
* new deployment to a website: InstallWebsite.sh B
* log() adds at the top of the buffer

## [0.3.3] - 2021.07.13

more tests
* each command is tested with all its parameters
* fix: replaceGroups() uses the parameter meta now

## [0.3.2] - 2021.07.12

Refactoring finished.
* All tests run successfully

## [0.3.1] - 2021.07.11

complete refactoring: new syntax for strings/patterns:
* prefix "r" defines a regular expression
* prefix "R" defines a regular expression, case insensitive
* prefix "I" defines a case insensitive string

This changes reduce the complexity of other syntax constructs and multiply the possibilities

syntax of string lists is now: <separator><prefix1><delimiter1><string1><delimiter1<separator>...

* previous syntax: Values=";a;b;c"
* new syntax: Values=;"a";/b/;'c'

## [0.2.1] - 2021.06.26

buffer macro in interpreted string, fix: command "load"

* interpreted string:
  * the macro ~[buffername] is now recognized: Than the macro is replaced with the content of buffer "buffername"
* command "load":
  * the default value of parameter "ouput" is now "input"

## [0.2.0] - 2021.06.24

Layout control, text_slave and installation tools

* Layout
  * new button "resize"
  * automatic calculation of ratio (grid item width/height) on screen size changes
  * reaction on changes in text field "layout"
* main
  * version
  * new application title
* new: text_slave.dart: command line version
* new: installation tools

## [0.1.0] - 2021.06.20 first code commit

* alfa version
* linux desktop version runs.
