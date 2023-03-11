
# Fabricio Rocha, 2023-03-04
# package require tcl 8.6 ;# complains package not found


# CSV columns starting from 1 for easier counting
set DEFS(CSVFILE) [file join . "BASIC - Comparados - Keywords.csv"]
set DEFS(PAGESDIR) [file join . genpages]
set DEFS(PAGESTEMPLATEFILE) [file join . genpages _template.txt]
set DEFS(BASICFAMILYLINE) 2
set DEFS(BASICVERSIONLINE) 3
set DEFS(KWFIRSTLINE) 5
set DEFS(MATFIRSTCOL) 4
set DEFS(KWCOL) 2
set DEFS(CSVSEP) ","
set DEFS(LINESEP) "\r\n"

array set filetable {}
set basicsLinks {}


proc ProcessCSV {} {
	global DEFS
	global filetable
	global basicsLinks

	try {
		set fh [open $DEFS(CSVFILE) r]
		set filecontents [read $fh]
		close $fh

	} on error {e} {
		puts "Error opening the matrix file: $e" 
	}
	
	csv2table $filecontents
	getImplementations
	
	scanMatrix
	
	exit
}


# 	WARNING: As it is, this procedure will not show even escaped quotes in each field
proc csv2table {csvdata} {
	upvar #0 filetable table
	global DEFS
	
	set linNum 0
	set charNum 0
	set lineFields {}
	set fieldData ""
	set fieldNum 0
	set escMode 0
	set prevChar ""
	
	while {[set c [string index $csvdata $charNum]] != ""} {
		if { $c == {"} } {
			if { $prevChar != {"}} {
				set escMode [expr !$escMode]
				incr charNum
				continue
			}
		}
		
		if { $c == $DEFS(CSVSEP) } {
			if { $escMode == 0 } {
				# Field complete
				lappend lineFields $fieldData
				incr fieldNum
				set prevChar $c
				set fieldData ""
				incr charNum
				continue
			}
		}
		
		if { $c == $DEFS(LINESEP) || "$c\n" == $DEFS(LINESEP) ||
			 "$c\r" == $DEFS(LINESEP) || "\n$c" == $DEFS(LINESEP) ||
			 "\r$c" == $DEFS(LINESEP) } {
			# Row complete
			lappend lineFields $fieldData
			array set table [list $linNum $lineFields]
			set prevChar ""
			set fieldData ""
			set fieldNum 0
			incr linNum
			incr charNum
			set lineFields {}
			continue
		}  
		
		# if we got here, it's just one more character to the current data field
		append fieldData $c
		set prevChar $c
		incr charNum
	}
}


# getImplementations
#	Prepares the basicsLinks list of DokuWiki links with all
#	the BASICs and its versions found in the table
proc getImplementations {} {
	global DEFS
	upvar #0 filetable table
	global basicsLinks
	
	set princLine [expr $DEFS(BASICFAMILYLINE) - 1 ]
	set subLine [expr $DEFS(BASICVERSIONLINE) - 1 ]
	
	set col [expr $DEFS(MATFIRSTCOL) - 1]
	
	set linPrinc [lindex [array get table $princLine] 1]
	set linSub [lindex [array get table $subLine] 1]
	
	set lastPrinc ""
	set lastSub ""
	
	set princ [lindex $linPrinc $col]
	set sub [lindex $linSub $col]
		
	# When a BASIC has versions, its name is written only at the first 
	#	column. This loop ensures the name found in such column is repeated
	#	for the versions.
	#	WARNING: It breaks if the table has a BASIC with more than one
	#		column without a version name.
	while { $princ != "" || $sub != "" } {
		if {$princ == ""} {
			set princ $lastPrinc
		} else {
			set lastPrinc $princ
		}
		
		set link [ string cat {[[:basics:} $princ ":" $sub {]]} ]
		
		lappend basicsLinks $link
		incr col
		set princ [lindex $linPrinc $col]
		set sub [lindex $linSub $col]
	}

}


# scanMatrix
#	Runs through all the implementation matrix, from its start line and
#	column
proc scanMatrix {} {
	upvar #0 filetable table
	global DEFS
	
	set idxmatlin [expr $DEFS(KWFIRSTLINE) - 1]

	set kwline [lindex [array get table $idxmatlin] 1]
	
	while { $kwline != {} } {
		processKeyword $kwline
		
		incr idxmatlin
		set kwline [lindex [array get table $idxmatlin] 1]
	}
}


# processKeyword
#	Creates the "Implemented by" and "With variations" links lists
#	from a given keyword line, matching it with links in
#	the global basicLinks list. It finishes calling kwPageProcess,
#	which creates or modify the keyword's page file.
proc processKeyword {kwdata} {
	global basicsLinks
	global DEFS
	
	set idxmatcol [expr $DEFS(MATFIRSTCOL) - 1]
	set idxkwcol [expr $DEFS(KWCOL) - 1]
	
	set implList {}
	set variList {}
	
	set kw [lindex $kwdata $idxkwcol]
	if {$kw == ""} return
	
	# This for runtime:
	puts -nonewline "Now processing $kw ... "
	flush stdout
	
	for {set col $idxmatcol} {$col <= [llength $kwdata]} {incr col} {
		set field [lindex $kwdata $col]

		if {$field == {}} {
			continue
		}
		
		set basic [lindex $basicsLinks [expr $col - $idxmatcol]]
		
		if {$field == "X" || $field == "x"} {
			lappend implList $basic
		} elseif {$field == "X*" || $field == "x*"} {
			lappend variList $basic
		} else {
			lappend variList "$basic $field"
		}
	}
	
	# TEST
	# puts stdout "---\n$kw\nImplemented by: $implList\nVariations: $variList"
	
	#Invoke the file handling procedure
	kwPageProcess $kw $implList $variList
	
}

# kwNameForFile
#	Returns a "clean" version of the keyword as typed in the matrix table,
#	suitable for usage as a DokuWiki file name. DW seems to trim off any
#	non-alphanum character left and right.
#	Rules here are:
#		- remove ( and/or ), used in the table for identifying some functions
#		- replace mid-name " " by _
#		- replace $ by -S, like in MID$ -> MID-S
#		- replace % by -PERCENT
#		- replace @ by -AT, as in BYTE@ -> BYTE-AT
#		- Lowercase? (actually it seems to have no effect)

proc kwNameForFile {kw} {
	set kff $kw
	while {[string match {*[)( $@%]*} $kff]} {
		set kff [ string trim $kff {) (} ]
		set kff [string replace $kff [string first " " $kff] [string first " " $kff] _ ]
		set kff [string replace $kff [string first {$} $kff] [string first {$} $kff] "-S" ]
		set kff [string replace $kff [string first {%} $kff] [string first {%} $kff] "-PERCENT" ]
		set kff [string replace $kff [string first {@} $kff] [string first {@} $kff] "-AT" ]
	}
	set kff [string tolower $kff]
	return $kff
}

proc kwNameForTitle {kw} {
	set kft $kw
	while {[string match {*[)( ]*} $kft]} {
		set kft [string replace $kft [string first " " $kft] [string first " " $kft] _ ]
		set kft [string replace $kft [string first {(} $kft] [string first {(} $kft] ]
		set kft [string replace $kft [string first {)} $kft] [string first {)} $kft] ]
	}
	
	return $kft
}

# kwPageProcess
#	Replaces the "Implemented by" and "With variations" sections
#	of a keyword's DokuWiki page file; 
proc kwPageProcess {kw implist varlist} {
	global DEFS
	
	set pgname [kwNameForFile $kw]
	set pgpath [file join $DEFS(PAGESDIR) "$pgname.txt"]
	set pgtitle [kwNameForTitle $kw]
	
	set pgcontents {}
	
	if { ![file exists $pgpath] } {
		# No existing page file with the keyword's name: create from template
		try {
			set fh [open $DEFS(PAGESTEMPLATEFILE) r]
			set pgcontents [read $fh]
			close $fh
		} on error {des det} {
			puts "Error trying to open the template file: $des\n$det"
			return
		}
		
		# The magic 8 here is the length of @!FILE!@.
		while {[set titlepos [string first "@!FILE!@" $pgcontents]] > -1} {
			set pgcontents 	[string replace $pgcontents \
								$titlepos \
								[expr $titlepos + 8 - 1] \
								$pgtitle \
							]
		}
		
	} else {
		try {
			set fh [open $pgpath r]
			set pgcontents [read $fh]
			close $fh
		} on error {des det} {
			puts "Error trying to open the keyword page file: $des\n$det"
			return
		}
	}
	
	# Turn the file contents into a list of lines
	set pglines [split $pgcontents $DEFS(LINESEP)]
	
	set impllinenum [lsearch -glob $pglines "**Implemented by:*"]
	set varilinenum [lsearch -glob $pglines "**With variations:*"]
	
	set newimpl "**Implemented by:** [join $implist ", "]"
	set newvari "**With variations:** [join $varlist ", "]"
	
	set pglines [lreplace $pglines $impllinenum $impllinenum $newimpl]
	set pglines [lreplace $pglines $varilinenum $varilinenum $newvari]
	
	# Save the new file
	try {
		set fh [open $pgpath w]
		puts -nonewline $fh [join $pglines "\n"]
		
		# For runtime feedback
		puts "file $pgpath saved!"
	} on error {des det} {
		puts "ERROR saving keyword $pgname page file: $des\n$det"
	} finally {
		close $fh
	}
	
	
}

# Invoke the startup procedure
ProcessCSV
