package ftb.app.templotar;

import haxe.crypto.Md5;
import haxe.ds.StringMap;
import haxe.Json;

import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author filt3rek
 */

class App {
	
	static var OUTPUT_DIR		= Sys.getCwd() + "out";
	static var INPUT_DIR		= Sys.getCwd();
	static var LANGS			= [ "fr" ];
	static var MIX_CDB			= null;
	static var SIGN				= "@@";
	static var REWRITE_GENERIC	= false;
	static var VERBOSE			= false;
	
	static function main() {
		var args	= Sys.args();
		
		function printUsage() {
			var err	= Sys.stderr();
				err.writeString( "Templotar v1.0 by Michal Romecki (contact@mromecki.fr, filt3r@free.fr)\n" );
				err.writeString( " Usage : Templotar <file> <file>...<file> [options]\n" );
				err.writeString( " Options : \n" );
				err.writeString( "  -o <path> : Set output directory (default : current directory/out)\n" );
				err.writeString( "  -i <path> : Set input directory (default : current directory)\n" );
				err.writeString( '  -l <ln>,<ln>,...<ln> : Set output languages (default : ${ LANGS[ 0 ] })\n' );
				err.writeString( "  -cdb <file> : Try to get indexes and translation from this file\n" );
				err.writeString( '  -rg  : Rewrite generics against preferred language\n' );
				err.writeString( '  -t <string> : Token used (default : $SIGN)\n' );
				err.writeString( '  -v  : Verbose\n' );
		}
		function prev( s ) return s.length >= 17 ? s.substr( 0, 17 ) + "..." : s;
		
		var i	= 0;
		if ( args.length == 0 ) {
			printUsage();
			return;
		}
		while ( i < args.length ) {
			var arg	= args[ i ].toLowerCase();
			if ( arg == "-h" || arg == "-help" || arg == "--help" || arg == "/?" || arg == "/help" ) {
				printUsage();
				return;
			}
			if ( arg	== "-o" ) {
				OUTPUT_DIR	= args[ i + 1 ];
				args.splice( i, 2 );
				continue;
			}
			if ( arg	== "-i" ) {
				INPUT_DIR	= args[ i + 1 ];
				args.splice( i, 2 );
				continue;
			}
			if ( arg	== "-l" ) {
				LANGS	= args[ i + 1 ].split( "," );
				args.splice( i, 2 );
				continue;
			}
			if ( arg	== "-t" ) {
				SIGN	= args[ i + 1 ];
				args.splice( i, 2 );
				continue;
			}
			if ( arg	== "-cdb" ) {
				MIX_CDB	= args[ i + 1 ];
				args.splice( i, 2 );
				continue;
			}
			if ( arg	== "-rg" ) {
				REWRITE_GENERIC	= true;
				args.splice( i, 1 );
				continue;
			}
			if ( arg	== "-v" ) {
				VERBOSE	= true;
				args.splice( i, 1 );
				continue;
			}
			i++;
		}
		
		if ( StringTools.endsWith( INPUT_DIR, "/" ) )	INPUT_DIR	= INPUT_DIR.substr( 0, INPUT_DIR.length - 1 );
		if ( StringTools.endsWith( OUTPUT_DIR, "/" ) )	OUTPUT_DIR	= OUTPUT_DIR.substr( 0, OUTPUT_DIR.length - 1 );
		if ( args.length == 0 ) {
			args	= FileSystem.readDirectory( INPUT_DIR ).filter( function ( elt ) {
				return !FileSystem.isDirectory( INPUT_DIR + "/" + elt );
			});
		}else{
			if ( args.length == 1 ) {
				if ( FileSystem.isDirectory( args[ 0 ] ) ) {
					INPUT_DIR	= args[ 0 ];
					args	= FileSystem.readDirectory( INPUT_DIR ).filter( function ( elt ) {
						return !FileSystem.isDirectory( INPUT_DIR + "/" + elt );
					});
				}
			}
		}
		var cdb			= new StringMap();
		var cdbMDMap	= new StringMap();
		if ( MIX_CDB != null )	{
			var scdb	= File.getContent( MIX_CDB );
			var jcdb	: {
				sheets	: Array < {
					name	: String,
					columns	: Array<Dynamic>,
					lines	: Array<Dynamic>
				}>
			}	= Json.parse( scdb );
			if ( VERBOSE )	Sys.println( 'cdb found to mix' );
			for ( sheet in jcdb.sheets ) {
				var a	= [];
				cdb.set( sheet.name , a );
				if ( VERBOSE )	Sys.println( 'lang : "${ sheet.name }" found' );
				for ( i in 0...sheet.lines.length ) {
					var s	= sheet.lines[ i ].s.split( '\"' ).join( '"' );
					a.push( s );
					if ( sheet.name == "generic" ) cdbMDMap.set( Md5.encode( s ), i );
					if ( VERBOSE )	Sys.println( 'line found : "${ prev( s ) }"' );
				}
			}
		}
		var tokInd	= 0;
		var md5s	= new StringMap();
		var all		= [ "generic" => [] ];
		for( lang in LANGS ){
			all.set( lang, [] );
			if ( !FileSystem.exists( OUTPUT_DIR ) )	{
				FileSystem.createDirectory( OUTPUT_DIR );
				if ( VERBOSE )	Sys.println( '"$OUTPUT_DIR" created' );
			}
			if ( !FileSystem.exists( OUTPUT_DIR + '/$lang' ) ) {
				FileSystem.createDirectory( OUTPUT_DIR + '/$lang' );
				if ( VERBOSE ) 	Sys.println( '"$OUTPUT_DIR/$lang" created' );
			}
		}
		for ( filename in args ) {
			var s		= File.getContent( INPUT_DIR + "/" + filename );
			var start	= 0;
			var ind		= 0;
			var out		= new StringMap();
			for( lang in LANGS ){
				out.set( lang, [] );
			}
			if ( REWRITE_GENERIC ) {
				out.set( "generic", [] );
			}
			if ( VERBOSE )	Sys.println( 'Processing "$filename" file' );
			while ( ( ind = s.indexOf( SIGN, start ) ) != -1 ) {
				var left	= s.substring( start, ind );
				var ind2	= s.indexOf( SIGN, ind + 2 );
				var token	= s.substring( ind, ind2 + 2 );
				var str		= token.substring( 2, token.length - 2 );
				start		= ind2 + 2;
				var enc		= Md5.encode( trimRNT( str ) );
				if ( VERBOSE )	Sys.println( 'Token "${ prev( str ) }" found' );
				if ( md5s.exists( enc ) ) {
					for ( lang in LANGS ) {
						out.get( lang ).push( left + all.get( lang )[ md5s.get( enc ) ] );
					}
					if ( REWRITE_GENERIC ) {
						out.get( "generic" ).push( left + SIGN + all.get( LANGS[ 0 ] )[ md5s.get( enc ) ] + SIGN );
					}
				}else {
					md5s.set( enc, tokInd );
					if ( VERBOSE ) Sys.println( 'Storing : "$enc"' );
					for ( lang in LANGS ) {
						if ( MIX_CDB != null && cdb.get( lang ) != null && cdbMDMap.get( enc ) != null && cdb.get( lang )[ cdbMDMap.get( enc ) ] != null ) {
							all.get( lang )[ tokInd ]	= cdb.get( lang )[ cdbMDMap.get( enc ) ];
						}else {
							all.get( lang )[ tokInd ]	= trimRNT( str );
						}
						if ( VERBOSE ) Sys.println( 'lang "$lang" : "${ prev( all.get( lang )[ tokInd ] ) }"' );
						out.get( lang ).push( left + all.get( lang )[ tokInd ] );
					}
					if ( REWRITE_GENERIC ) {
						out.get( "generic" ).push( left + SIGN + all.get( LANGS[ 0 ] )[ tokInd ] + SIGN );
						all.get( "generic" )[ tokInd ]	= all.get( LANGS[ 0 ] )[ tokInd ];
					}else {
						all.get( "generic" )[ tokInd ]	= trimRNT( str );
					}
					tokInd++;
				}
			}
			for ( lang in LANGS ) {
				out.get( lang ).push( s.substr( start ) );
				File.saveContent( OUTPUT_DIR + '/$lang/' + filename, out.get( lang ).join( "" ) );
				if ( VERBOSE )	Sys.println( 'Saving $OUTPUT_DIR/$lang/$filename' );
			}
			if ( REWRITE_GENERIC ) {
				out.get( "generic" ).push( s.substr( start ) );
				File.saveContent( INPUT_DIR + '/' + filename, out.get( "generic" ).join( "" ) );
				if ( VERBOSE )	Sys.println( 'Saving generic : $INPUT_DIR/$filename' );
			}
		}
		
		var emptyCDB	= '{
	"sheets"	: [
		{
			"name"		: "generic",
			"columns"	: [
				{
					"typeStr"	: "0",
					"name"		: "id",
					"display"	: null
				},
				{
					"typeStr"	: "1",
					"name"		: "s",
					"display"	: null
				}
			],
			"lines": [';
			for ( i in 0...all.get( "generic" ).length ) {
				var r	= all.get( "generic" )[ i ].split( '\"' ).join( '\\"' );
				emptyCDB += '{
					"id"	: "Text_$i",
					"s"		: "$r"
				}';
				if ( i < all.get( "generic" ).length - 1 )	emptyCDB += ",";
			}
			emptyCDB +=	'],
			"separators"	: [],
			"props"			: {
				"displayColumn"	: "s"
			}
		},';
		for ( j in 0...LANGS.length ) {
			var lang	= LANGS[ j ];
			emptyCDB	+= '		
		{
			"name"		: "$lang",
			"columns"	: [
				{
					"typeStr"	: "6:generic",
					"name"		: "lid"
				},
				{
					"typeStr"	: "1",
					"name"		: "s",
					"display"	: null
				}
			],
			"lines": [';
			for ( i in 0...all.get( lang ).length ) {
				var r	= all.get( lang )[ i ].split( '\"' ).join( '\\"' );
				emptyCDB += '{
					"lid"	: "Text_$i",
					"s"		: "$r"
				}';
				if ( i < all.get( lang ).length - 1 )	emptyCDB += ",";
			}
						
			emptyCDB +='],
			"separators"	: [],
			"props"			: {}
		}';
			if ( j < LANGS.length - 1 )	emptyCDB	+= ",";
		}
		emptyCDB += '
	],
	"customTypes"	: []
}';
		File.saveContent( OUTPUT_DIR + "/texts.cdb", emptyCDB );
	}
	
	static function trimRNT( s : String ) {
		while ( s.split( "\t" ).length > 1 ){
			s = s.split( "\t" ).join( "" );
		}
		while ( s.split( "\r" ).length > 1 ){
			s = s.split( "\r" ).join( "" );
		}
		while ( s.split( "\n" ).length > 1 ){
			s = s.split( "\n" ).join( "" );
		}
		return s;
	}
}