\ collcount.fs
\ Jim Smason
\ CSF331 Spring 2019
\ Assignment 7
\ Exercise B
\ This program uses the collatz conjecture.

: collatz { n -- n }
	n 0 = if
		0
	else
	    n 2 mod 0 = if
			n 2 /
		else
			n 3 * 1 +
		endif
	endif
;

: collcount_helper { n -- c }
	n 1 = if
		0
	else
		n
		collatz
		dup 1 = if
			1
			nip
		else
		recurse
		dup 1 +
		nip
		endif
	endif
;

: collcount { n -- c }
	n 1 +
	collcount_helper
;