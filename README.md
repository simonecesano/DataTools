    sqltool.pl [-CcDFfhiSUuv] [long options...] - create sql snippets
    	                         
    	create statements from input lookup table:
    	-i --in                    create "in" clause
    	-c --case                  create "case" clause
    	-u[=STR] --update[=STR]    create "update" statement
    	                         
    	create select statements for a given table and field:
    	-U[=STR] --unique[=STR]    get unique values
    	-C[=STR] --count[=STR]     get unique values and count of records
    	-D[=STR] --values[=STR]    get list and count of different values for
    	                           fields (unimplemented)
    	                         
    	-S[=STR] --sub[=STR]       sub to apply to input values
    	-f --first                 force first line as field name
    	-F --no_header             first line is NOT field name
    	                         
    	-v --verbose               print extra stuff
    	-h --help                  print usage message and exit

# sqltoo.pl

This tool creates SQL snippets from input data.

## case

    --case

generates a case statement from an input table. A table like this:

| gender | type | h_group |
|--------|------|---------|
| m      | 1    | a       |
| m      | 2    | b       |
| m      | 3    | c       |
| f      | 1    | d       |
| f      | 2    | e       |

will generate a statement like this

    case
	    gender = "f"     and type = "1"    then "d"
	    gender = "f"     and type = "2"    then "e"
	    gender = "m"     and type = "1"    then "a"
	    gender = "m"     and type = "2"    then "b"
	    gender = "m"     and type = "3"    then "c"
    end as h_group

## in

    --in

generates an "in" clause. A table like this:

| gender |
|--------|
| m      |
| m      |
| m      |
| f      |
| f      |

will generate a statement like this:

    gender in (
	       "f",
	       "m"
    )

and a more complex one like this:

| gender | type |
|--------|------|
| m      | 1    |
| m      | 2    |
| m      | 3    |
| f      | 1    |
| f      | 2    |
    
will generate a statement like this:

    gender || type in (
		       "f" || "1",
		       "f" || "2",
		       "m" || "1",
		       "m" || "2",
		       "m" || "3"
    )
    
