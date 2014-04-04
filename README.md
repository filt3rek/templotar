# Templotar

It's a light command-line tool written in [Haxe](http://haxe.org) that helps to manage templates and multi language localization.

	Usage : Templotar <file> <file>...<file> [options]
	 Options :
	  -o <path> : Set output directory (default : current directory/out)
	  -i <path> : Set input directory (default : current directory)
	  -l <ln>,<ln>,...<ln> : Set output languages (default : fr)
	  -cdb <file> : Try to get indexes and translation from this file
	  -t <string> : Token used (default : @@)
	  -rg : Rewrite generics agains preferrred language
	  -v  : Verbose

## Example

### Templating

Let's say we have 2 templo templates like that :

	// shell.mtt
	<html>
		<head>
			<title>My Website</title>
		</head>
		<body>
			<ul class="menu">
				<li><a href="#">News</a></li>
				<li><a href="#">Movies</a></li>
				<li><a href="#">Connect</a></li>
			</div>
			<div class="content">::raw __content__::</div>
			<div id="footer">
				<p>All rights reserved</p>
			</div>
		</body>
	</html>

	
	// news.mtt
	::use 'shell.mtt'::
	<h1>News</h1>
	<div class="news">
		<p>Here are the news !</p>
	</div>
	::end::
	
You build all your website in your favourite language...

### Starting translation

In order to begin the translation step, you have to surround all the words and sentences in all the templates with a token, let's say it's "@@" by default.

So the templates files look like that now :

	// shell.mtt
	<html>
		<head>
			<title>@@My Website@@</title>
		</head>
		<body>
			<ul class="menu">
				<li><a href="#">@@News@@</a></li>
				<li><a href="#">@@Movies@@</a></li>
				<li><a href="#">@@Connect@@</a></li>
			</div>
			<div class="content">::raw __content__::</div>
			<div id="footer">
				<p>@@All rights reserved@@</p>
			</div>
		</body>
	</html>
		
	
	// news.mtt
	::use 'shell.mtt'::
	<h1>@@News@@</h1>
	<div class="news">
		<p>@@Here are the news !@@</p>
	</div>
	::end::
	
These new templates will be the **generic** ones.

### Get the multi language templates

	Templotar -i generic shell.mtt news.mtt -o . -l en,fr

With this command we'll get 2 folders corresponding to the 2 generated languages : **en** and **fr** that contain the generated templates filled by default with the language used in the **generic** templates.

We'll also get a **.cdb** file ([CastleDB](http://castledb.org)). Once opened, we'll see something like that :
	
![Screenshot 1](http://mromecki.fr/blog/post/59/screen1.jpg)
	
When a word or a sentence is updated in the **.cdb** file like that :
	
![Screenshot 2](http://mromecki.fr/blog/post/59/screen2.jpg)
		
Then we can get the **new generated** templates like that :
	
	Templotar -i generic shell.mtt news.mtt -o . -l en,fr **-cdb texts.cdb**
	
From now, this process can be done as many times as a new word or sentance is inserted into a **generic** template or a translation is done.