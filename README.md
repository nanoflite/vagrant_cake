# Vagrant box for CakePHP development #

Create a vagrant box starting from a bare lucid32.box, using puppet to bring up apache, mysql and cake.

## Configuration ##

I used a git submodule for the cakephp core source, using the commit tag for version 2.4.

You can connect to the box at http://10.11.12.13

The database 'app' is created with user 'app' and pasword 'app'. You can change this in the puppet/cakephp.pp file.

## Thanks ##

Based upon the following blog post: http://matteolandi.blogspot.be/2012/01/about-cakephp-and-vagrant.html

