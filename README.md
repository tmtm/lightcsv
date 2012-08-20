LightCsv
========

Description
-----------

LightCsv is CSV paresr.

Installation
------------

    % gem install lightcsv

Differ from csv.rb
------------------

* CSV record separator is LF, CR or CR LF.
* LightCsv never returns nil. The empty column is "".

Examples
--------

    LightCsv.foreach(filename){|row| ...}
    LightCsv.readlines(filename)   #=> [[col1, col2, ...], ...]
    LightCsv.parse(string){|row| ...}
    LightCsv.parse(string)         #=> [col1, col2, ...], ...]

Copyright
---------

Copyright (c) 2007 TOMITA Masahiro <tommy@tmtm.org>

License
-------

Ruby's license <http://www.ruby-lang.org/en/about/license.txt>
