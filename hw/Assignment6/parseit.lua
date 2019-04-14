-- parseit.lua
-- Jim Samson
-- 26 Feb 2019

-- Code by Dr. Chappell
-- For CS F331 / CSCE A331 Spring 2019
-- Recursive-Descent Parser #4: Expressions + Better ASTs
-- Requires lexit.lua

-- Grammar
-- Start symbol: program
--     (01) program	    →  	stmt_list
--     (02) stmt_list	→  	{ statement }
--     (03) statement	→  	‘write’ ‘(’ write_arg { ‘,’ write_arg } ‘)’
--     (04)  	        |  	‘def’ ID ‘(’ ‘)’ stmt_list ‘end’
--     (05)  	        |  	‘if’ expr stmt_list { ‘elseif’ expr stmt_list } [ ‘else’ stmt_list ] ‘end’
--     (06)  	        |  	‘while’ expr stmt_list ‘end’
--     (07)  	        |  	‘return’ expr
--     (08)  	        |  	ID ( ‘(’ ‘)’ | [ ‘[’ expr ‘]’ ] ‘=’ expr )
--     (09) write_arg	→  	‘cr’
--     (10)  	        |  	STRLIT
--     (11)  	        |  	expr
--     (12) expr	    →  	comp_expr { ( ‘&&’ | ‘||’ ) comp_expr }
--     (13) comp_expr	→  	‘!’ comp_expr
--     (14)  	        |  	arith_expr { ( ‘==’ | ‘!=’ | ‘<’ | ‘<=’ | ‘>’ | ‘>=’ ) arith_expr }
--     (15) arith_expr	→  	term { ( ‘+’ | ‘-’ ) term }
--     (16) term	    →  	factor { ( ‘*’ | ‘/’ | ‘%’ ) factor }
--     (17) factor	    →  	‘(’ expr ‘)’
--     (18)  	        |  	( ‘+’ | ‘-’ ) factor
--     (19)  	        |  	NUMLIT
--     (20)  	        |  	( ‘true’ | ‘false’ )
--     (21)  	        |  	‘readnum’ ‘(’ ‘)’
--     (22)  	        |  	ID [ ‘(’ ‘)’ | ‘[’ expr ‘]’ ]

-- Grammar
-- Start symbol: expr
--
--     expr    ->  term { ("+" | "-") term }
--     term    ->  factor { ("*" | "/") factor }
--     factor  ->  ID
--              |  NUMLIT
--              |  "(" expr ")"
--
-- All operators (+ - * /) are left-associative.
--
-- AST Specification
-- - For an ID, the AST is { SIMPLE_VAR, SS }, where SS is the string
--   form of the lexeme.
-- - For a NUMLIT, the AST is { NUMLIT_VAL, SS }, where SS is the string
--   form of the lexeme.
-- - For expr -> term, then AST for the expr is the AST for the term,
--   and similarly for term -> factor.
-- - Let X, Y be expressions with ASTs XT, YT, respectively.
--   - The AST for ( X ) is XT.
--   - The AST for X + Y is { { BIN_OP, "+" }, XT, YT }. For multiple
--     "+" operators, left-asociativity is reflected in the AST. And
--     similarly for the other operators.


local parseit = {}  -- Our module

local lexit = require "lexit"


-- Variables

-- For lexit iteration
local iter          -- Iterator returned by lexit.lex
local state         -- State for above iterator (maybe not used)
local lexer_out_s   -- Return value #1 from above iterator
local lexer_out_c   -- Return value #2 from above iterator

-- For current lexeme
local lexstr = ""   -- String form of current lexeme
local lexcat = 0    -- Category of current lexeme:
                    --  one of categories below, or 0 for past the end


-- Symbolic Constants for AST

local STMT_LIST    = 1
local WRITE_STMT   = 2
local FUNC_DEF     = 3
local FUNC_CALL    = 4
local IF_STMT      = 5
local WHILE_STMT   = 6
local RETURN_STMT  = 7
local ASSN_STMT    = 8
local CR_OUT       = 9
local STRLIT_OUT   = 10
local BIN_OP       = 11
local UN_OP        = 12
local NUMLIT_VAL   = 13
local BOOLLIT_VAL  = 14
local READNUM_CALL = 15
local SIMPLE_VAR   = 16
local ARRAY_VAR    = 17


-- Utility Functions

-- advance
-- Go to next lexeme and load it into lexstr, lexcat.
-- Should be called once before any parsing is done.
-- Function init must be called before this function is called.
local function advance()
    -- Advance the iterator
    lexer_out_s, lexer_out_c = iter(state, lexer_out_s)

    -- If we're not past the end, copy current lexeme into vars
    if lexer_out_s ~= nil then
        lexstr, lexcat = lexer_out_s, lexer_out_c
    else
        lexstr, lexcat = "", 0
    end
end


-- init
-- Initial call. Sets input for parsing functions.
local function init(prog)
    iter, state, lexer_out_s = lexit.lex(prog)
    advance()
end


-- atEnd
-- Return true if pos has reached end of input.
-- Function init must be called before this function is called.
local function atEnd()
    return lexcat == 0
end


-- matchString
-- Given string, see if current lexeme string form is equal to it. If
-- so, then advance to next lexeme & return true. If not, then do not
-- advance, return false.
-- Function init must be called before this function is called.
local function matchString(s)
    if lexstr == s then
        advance()
        return true
    else
        return false
    end
end


-- matchCat
-- Given lexeme category (integer), see if current lexeme category is
-- equal to it. If so, then advance to next lexeme & return true. If
-- not, then do not advance, return false.
-- Function init must be called before this function is called.
local function matchCat(c)
    if lexcat == c then
        advance()
        return true
    else
        return false
    end
end


-- Primary Function for Client Code

-- "local" statements for parsing functions
local parse_expr
local parse_term
local parse_factor
local parse_program
local parse_stmt_list
local parse_statement
local parse_call
local parse_comp_expr
local parse_arith_expr
local parse_write_arg

-- parse
-- Given program, initialize parser and call parsing function for start
-- symbol. Returns pair of booleans & AST. First boolean indicates
-- successful parse or not. Second boolean indicates whether the parser
-- reached the end of the input or not. AST is only valid if first
-- boolean is true.
function parseit.parse(prog)
    -- Initialization
    init(prog)

    -- Get results from parsing
    local good, ast = parse_program()  -- Parse start symbol
    local done = atEnd()

    -- And return them
    return good, done, ast
end

-- function parse_program
function parse_program()
	local good, ast
	good, ast = parse_stmt_list()
    return good, ast
end

-- Parsing function for nonterminal "stmt_list".
-- Function init must be called before this function is called.
function parse_stmt_list()
	local good, ast, ast2

	ast = { STMT_LIST }
	while true do
		if lexstr ~= "write"
			and lexstr ~= "def"
			and lexstr ~= "if"
			and lexstr ~= "while"
			and lexstr ~= "return"
			and lexcat ~= lexit.ID then
			return true, ast
		end

		good, ast2 = parse_statement()
		if not good then
			return false, nil
		end

		table.insert(ast, ast2)
	end
	return good, ast
end


-- function parse_statement()
function parse_statement()
	local good, ast, ast2, savelex
	savelex = lexstr

	-- Handle write Statements
	if matchString("write") then
		if matchString("(") then
			good, ast = parse_write_arg()
			if not good then
				return false, nil
			end
		end

		ast2 = { WRITE_STMT, ast }

		while true do
			if not matchString(",") then
				break
			end

			good, ast = parse_write_arg()

			if not good then
				return false, nil
			end

			table.insert(ast2, ast)
		end

		if not matchString(")") then
			return false, nil
		end
		return true, ast2

	-- Handle Function Definitions
	elseif matchString("def") then
		savelex = lexstr
		if matchCat(lexit.ID) then
			if not (matchString("(") and matchString(")")) then
				return false, nil
			end
			good, ast2 = parse_stmt_list()
			if not good then
				return false, nil
			end
		else
			return false, nil
		end

		ast = { FUNC_DEF, savelex, ast2 }
		if matchString('end') then
			return true, ast
		end
	return true, ast


-- Handle While Statement
	elseif matchString('while') then
		local ast1, ast2
		good, ast1 = parse_expr()
		if not good then 
			return false, nil
		end

		good, ast2 = parse_stmt_list()
		if not good then
			return false, nil
		end

		if not matchString('end') then
			return false, nil
		end

		ast1 = { WHILE_STMT, ast1, ast2 }
		return good, ast1

-- Handle If statements
	elseif matchString('if') then
		local expr, stmt_list
		good, expr = parse_expr()
		if not good then
			return false, nil
		end
		good, stmt_list = parse_stmt_list()
		if not good then
			return false, nil
		end
		ast = { IF_STMT, expr, stmt_list }
		while true do
			savelex = lexstr
			if not matchString('elseif') then
				break
			end
			good, expr = parse_expr()
			if not good then
				return false, nil
			end
			good, stmt_list = parse_stmt_list()
			if not good then
				return false, nil
			end
			table.insert(ast, expr)
			table.insert(ast, stmt_list)
		end
		if matchString('else') then
			good, stmt_list = parse_stmt_list()
			if not good then
				return false, nil
			end
			table.insert(ast, stmt_list)
		end
		if not matchString('end') then
			return false, nil
		end
		return true, ast

	elseif matchString("return") then
		good, expr = parse_expr()
		if not good then
			return false, nil
		end
		return true, { RETURN_STMT, expr}

	elseif matchCat(lexit.ID) then
		if matchString('(') then
			if not matchString(')') then
				return false, nil
			end
			ast1 = { FUNC_CALL, savelex }
		
		elseif matchString('[') then
			good, ast1 = parse_expr()
			if not good then
				return false, nil
			end 
			
			if not (matchString(']') and matchString('=')) then
				return false, nil
			end

			good, ast2 = parse_expr()
			if not good then
				return false, nil
			end 

			return true, { ASSN_STMT, { ARRAY_VAR, savelex, ast1 }, ast2 }
		
		elseif matchString("=") then
			ast1 = { ASSN_STMT, {SIMPLE_VAR, savelex}}
			good, ast2 = parse_expr()
			if not good then
				return false, nil
			end
			table.insert(ast1, ast2)
		else 
			return false, nil
		end	
		--ast = { ASSN_STMT, ast, ast2 }
		return true, ast1

	else
		return false, nil
	end
end

-- Parsing Functions

-- Each of the following is a parsing function for a nonterminal in the
-- grammar. Each function parses the nonterminal in its name and returns
-- a pair: boolean, AST. On a successul parse, the boolean is true, the
-- AST is valid, and the current lexeme is just past the end of the
-- string the nonterminal expanded into. Otherwise, the boolean is
-- false, the AST is not valid, and no guarantees are made about the
-- current lexeme. See the AST Specification near the beginning of this
-- file for the format of the returned AST.

-- NOTE. Declare parsing functions "local" above, but not below. This
-- allows them to be called before their definitions.


-- parse_expr
-- Parsing function for nonterminal "expr".
-- Function init must be called before this function is called.
function parse_expr()
	local good, ast, ast2, savelex

	good, ast = parse_comp_expr()

	while true do
		savelex = lexstr
		if not (matchString("&&") or matchString("||")) then
			break
		end
		good, ast2 = parse_comp_expr()
		if not good then
			return false, nil
		end
		ast = { { BIN_OP, savelex }, ast, ast2 }
	end
	return good, ast
end

function parse_comp_expr()
	local good, ast, ast2, ast3
	if matchString('!') then
		good, ast = parse_comp_expr()
        if not good then
            return false, nil
        end
		ast = { { UN_OP, "!" }, ast}
		return true, ast
	end
	good, ast = parse_arith_expr()
	if not good then
		return false, nil
	end

	while true do
		local savelex = lexstr
		if not matchString("==") 
		and not matchString("!=")
		and not matchString("<")
		and not matchString("<=")
		and not matchString(">")
		and not matchString(">=") then
			return good, ast
		else
			good, ast2 = parse_arith_expr()
			if not good then
				return false, nil
			end
			ast = { { BIN_OP, savelex }, ast, ast2 }
		end
	end
	return good, ast
end

function parse_arith_expr()
	local good, ast, ast2, savelex
	good, ast = parse_term()
	if not good then
		return false, nil
	end
	while true do
		savelex = lexstr
		if not matchString('+') and not matchString('-') then
			break
		end
		
		good, ast2 = parse_term()
		if not good then
			return false, nil
		end
		ast = { { BIN_OP, savelex }, ast, ast2 }
	end
	return true, ast
end

function parse_write_arg()
	local good, ast, savelex
	savelex = lexstr

	if matchString('cr') then
		ast = { CR_OUT }
		good = true
	elseif matchCat(lexit.STRLIT) then
		ast = { STRLIT_OUT, savelex }
		good = true
	else
		good, ast = parse_expr()
		if not good then
			return false, nil
		end
		good = true
	end
	return good, ast
end

-- parse_term
-- Parsing function for nonterminal "term".
-- Function init must be called before this function is called.
function parse_term()
    local good, ast, saveop, newast

    good, ast = parse_factor()
    if not good then
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("*") and not matchString("/") and not matchString("%") then
            break
        end

        good, newast = parse_factor()
        if not good then
            return false, nil
        end

        ast = { { BIN_OP, saveop }, ast, newast }
    end

    return true, ast
end


-- parse_factor
-- Parsing function for nonterminal "factor".
-- Function init must be called before this function is called.
function parse_factor()
	local good, ast, ast2, old_lexstr
	old_lexstr = lexstr

	if matchString('(') then
		good, ast = parse_expr()
		if not good then
			return false, nil
		end 
		
		if not matchString(')') then
			return false, nil
		end

	elseif matchString('+')
	or matchString('-')
	or matchString('%') then
		good, ast2 = parse_factor()
		if not good then
			return false, nil
		end
		ast = { {UN_OP, old_lexstr}, ast2 }

	elseif matchCat(lexit.NUMLIT) then
		good = true
		ast = { NUMLIT_VAL, old_lexstr }

	elseif matchString('true') or matchString('false') then
		return true, { BOOLLIT_VAL, old_lexstr }
	
	elseif matchString('readnum') then
		if matchString('(') and matchString(')') then
			return true, { READNUM_CALL }
		else
			return false, nil
		end
	
	elseif matchCat(lexit.ID) then
		if matchString('(') and matchString(')') then
			return true, { FUNC_CALL, old_lexstr }

		elseif matchString('[') then
			good, ast2 = parse_expr()
			if not good or not matchString("]") then
				return false, nil
			end
			return true, { ARRAY_VAR, old_lexstr, ast2 }
		end

		return true, { SIMPLE_VAR, old_lexstr }

	else
		if not good then
			return false, nil
		end
	end	
	return good, ast
end


-- Module Export

return parseit

