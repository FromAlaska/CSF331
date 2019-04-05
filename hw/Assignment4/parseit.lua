-- parseit.lua
-- Jim Samson
-- 26 Feb 2019

-- Code by Dr. Chappell
-- For CS F331 / CSCE A331 Spring 2019
-- Recursive-Descent Parser #4: Expressions + Better ASTs
-- Requires lexit.lua


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
local parse_lvalue

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
		if lexstr ~= "list"
			and lexstr ~= "write"
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

    
-- Handle Input statements
	if matchString("list") then
		good, ast = parse_lvalue()
		return good, { STMT_LIST, ast }

        -- Handle Func Definitions
	elseif matchString("func") then
		if matchCat(lexit.ID) then
			savelex = lexstr
			advance()
		else
			return false, nil
		end
		good, ast2 = parse_stmt_list()
		if not good then
			return false, nil
		end
		good = matchString('end')
		ast = { FUNC_STMT, savelex, ast2 }
        return good, ast
        
-- Handle Call statements
	elseif matchString('call') then
		good, ast = parse_call()
		return good, ast

-- Handle Print Statements
	elseif matchString("print") then
		good, ast = parse_print_arg()
        if not good then
            return false, nil
        end

        ast2 = { PRINT_STMT, ast }

        while true do
            if not matchString(";") then
                break
			end

            good, ast = parse_print_arg()
            if not good then
                return false, nil
            end

            table.insert(ast2, ast)
		end
        return true, ast2


-- Handle While Statement
	elseif matchString('while') then
		local ast3, ast4
		good, ast3 = parse_expr()
		if not good then
			return false, nil
		end
		good, ast4 = parse_stmt_list()
		if not good or not matchString('end') then
			return false, nil
		end
		ast = { WHILE_STMT, ast3, ast4 }
		return true, ast

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

	elseif matchCat(lexit.ID) then
		good, ast = parse_lvalue()
		if not good then
			return false, nil
		end
		if not matchString('=') then
			return false, nil
		end
		good, ast2 = parse_expr()
		if not good then
			return false, nil
		end
		ast = { ASSN_STMT, ast, ast2 }
		return true, ast

	else
		advance()
		return false, nil
	end
end

function parse_lvalue()
	local good, ast
	if matchCat(lexit.ID) then
		lexer.preferOp()
		ast = { SIMPLE_VAR, lexstr }
		good = true
		advance()
		if match_string('[') then
			local good, ast2 = parse_expr()
			if not good then
				return false, nil
			end
			ast = { ARRAY_VAR, ast[2], ast2 }
			if not match_string(']') then
				return false, nil
			end
		end
	else
		good = false
	end
	return good, ast
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
		if not matchString("&&") and not matchString("||") then
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
        if not matchString("*") and not matchString("/") then
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
    local savelex, good, ast

    savelex = lexstr
    if matchCat(lexit.ID) then
        return true, { SIMPLE_VAR, savelex }
    elseif matchCat(lexit.NUMLIT) then
        return true, { NUMLIT_VAL, savelex }
    elseif matchString("(") then
        good, ast = parse_expr()
        if not good then
            return false, nil
        end

        if not matchString(")") then
            return false, nil
        end

        return true, ast
    else
        return false, nil
    end
end


-- Module Export

return parseit
