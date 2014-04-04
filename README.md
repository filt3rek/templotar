# Templotar

It's a light command-line tool that will :

 * Write the wanted languages templates filled by defaut with the favourite language
 * Write a .cdb (CastleDB) file, to use for translation (see below)
 * Rewrite the wanted languages templates filled with the new .cdb file containing entire or partial translation (and so on...)

## How to use it

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
		
Let's translate the generic templates into english (the favourite language here) and french :

	Templotar -i generic shell.mtt news.mtt -o . -l en,fr
