-- lexit.lua
-- Jim Samson
-- 2/18/2019
-- Modified code from Dr. Glenn Chappell's lexer.lua

-- based on
-- lexer.lua
-- VERSION 3
-- Glenn G. Chappell
-- Started: 6 Feb 2019
-- Updated: 8 Feb 2019
--
-- For CS F331 / CSCE A331 Spring 2019
-- In-Class Lexer Module

-- History:
--   v1. Framework written. Lexer treats every character as punctuation.
--   v2. Add states LETTER, DIGIT, DIGDOT, with handlers. Write
--       skipWhitespace. Add utility function nextChar.
--   v3. Finished (hopefully). Add states DOT, PLUS, MINUS, STAR.

-- Usage:
--
--    program = "print a+b;"  -- program to lex
--    for lexstr, cat in lexer.lex(program) do
--        -- lexstr is the string form of a lexeme.
--        -- cat is a number representing the lexeme category.
--        --  It can be used as an index for array lexer.catnames
--    end


-- *********************************************************************
-- Module Table Initialization
-- *********************************************************************


local lexit = {}  -- Our module; members are added below


-- *********************************************************************
-- Public Constants
-- *********************************************************************


-- Numeric constants representing lexeme categories
lexit.KEY = 1
lexit.ID = 2
lexit.NUMLIT = 3
lexit.STRLIT = 4
lexit.OP = 5
lexit.PUNCT = 6
lexit.MAL = 7


-- catnames
-- Array of names of lexeme categories.
-- Human-readable strings. Indices are above numeric constants.
lexit.catnames = {
    "Keyword",
    "Identifier",
    "NumericLiteral",
    "StringLiteral",
    "Operator",
    "Punctuation",
    "Malformed"
    
}


-- *********************************************************************
-- Kind-of-Character Functions
-- *********************************************************************

-- All functions return false when given a string whose length is not
-- exactly 1.


-- isLetter
-- Returns true if string c is a letter character, false otherwise.
local function isLetter(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "A" and c <= "Z" then
        return true
    elseif c >= "a" and c <= "z" then
        return true
    else
        return false
    end
end


-- isDigit
-- Returns true if string c is a digit character, false otherwise.
local function isDigit(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "0" and c <= "9" then
        return true
    else
        return false
    end
end


-- isWhitespace
-- Returns true if string c is a whitespace character, false otherwise.
local function isWhitespace(c)
    if c:len() ~= 1 then
        return false
    elseif c == " " or c == "\t" or c == "\n" or c == "\r"
      or c == "\f" then
        return true
    else
        return false
    end
end


-- isIllegal
-- Returns true if string c is an illegal character, false otherwise.
local function isIllegal(c)
    if c:len() ~= 1 then
        return false
    elseif isWhitespace(c) then
        return false
    elseif c >= " " and c <= "~" then
        return false
    else
        return true
    end
end



-- *********************************************************************
-- The Lexer
-- *********************************************************************


-- lex
-- Our lexit
-- Intended for use in a for-in loop:
--     for lexstr, cat in lexit.lex(program) do
-- Here, lexstr is the string form of a lexeme, and cat is a number
-- representing a lexeme category. (See Public Constants.)
function lexit.lex(program)
    -- ***** Variables (like class data members) *****

    local pos       -- Index of next character in program
                    -- INVARIANT: when getLexeme is called, pos is
                    --  EITHER the index of the first character of the
                    --  next lexeme OR program:len()+1
    local state     -- Current state for our state machine
    local ch        -- Current character
    local lexstr    -- The lexeme, so far
    local category  -- Category of lexeme, set when state set to DONE
    local handlers  -- Dispatch table; value created later
    local previousCat 
    local previousLex

    -- ***** States *****

    local DONE = 0
    local START = 1
    local LETTER = 2
    local DIGIT = 3
    local EXP = 4
    local PLUS = 5
    local MINUS = 6
    local STAR = 7
    local STRLIT = 8
    local OPERATOR = 10
    local DBLOPERATOR = 11

    -- ***** Character-Related Utility Functions *****

    -- currChar
    -- Return the current character, at index pos in program. Return
    -- value is a single-character string, or the empty string if pos is
    -- past the end.

    -- Maximal Munch function
    local function maxMunch()
        return previousCat == lexit.ID
        or previousCat == lexit.NUMLIT
        or previousLex == ")"
        or previousLex == "]"
        or previousLex == "true"
        or previousLex == "false"
    end

    
    local function currChar()
        return program:sub(pos, pos)
    end

    -- nextChar
    -- Return the next character, at index pos+1 in program. Return
    -- value is a single-character string, or the empty string if pos+1
    -- is past the end.
    local function nextChar()
        return program:sub(pos+1, pos+1)
    end

    local function nextNextChar()
    	return program:sub(pos+2, pos+2)
    end

    -- drop1
    -- Move pos to the next character.
    local function drop1()
        pos = pos+1
    end

    -- add1
    -- Add the current character to the lexeme, moving pos to the next
    -- character.
    local function add1()
        lexstr = lexstr .. currChar()
        drop1()
    end

    -- skipWhitespace
    -- Skip whitespace and comments, moving pos to the beginning of
    -- the next lexeme, or to program:len()+1.
    local function skipWhitespace()
        while true do
            while isWhitespace(currChar()) do
                drop1()
            end

            if currChar() ~= "#" then  -- Comment?
                break
            end
            drop1()

            while true do
                if currChar() == "\n" then
                    drop1()
                    break
                elseif currChar() == "" then  -- End of input?
                   return
                end
                drop1()
            end
        end
    end

    -- ***** State-Handler Functions *****

    -- A function with a name like handle_XYZ is the handler function
    -- for state XYZ

    local function handle_DONE()
        io.write("ERROR: 'DONE' state should not be handled\n")
        assert(0)
    end

    local function handle_START()
        if isIllegal(ch) then
            add1()
            state = DONE
            category = lexit.MAL
        elseif isLetter(ch) or ch == "_" then
            add1()
            state = LETTER
        elseif isDigit(ch) then
            add1()
            state = DIGIT
        elseif ch == "+" then
            add1()
            state = PLUS
        elseif ch == "-" then
            add1()
            state = MINUS
        elseif ch == "'" or ch == '"' then
            state = STRLIT
        elseif ch == "=" or ch =="!" or ch == ">" or ch == "<" then 
            add1()
            state = OPERATOR
        elseif ch == "/" or ch == "%" or ch == "[" or ch == "]" or ch == "*" then
            add1()
            state = DONE
            category = lexit.OP
        elseif ch == "&" or ch == "|" then
            add1()
            state = DBLOPERATOR
        else 
            add1()
            state = DONE
            category = lexit.PUNCT
        end 
    end

    local function handle_LETTER()
        if isLetter(ch) or isDigit(ch) or ch == "_" then
            add1()
        else
            state = DONE
            if     lexstr == "readnum"  or lexstr == "cr"    
            	or lexstr == "else"  or lexstr == "elseif"    
            	or lexstr == "end"   or lexstr == "false"
            	or lexstr == "def"  or lexstr == "if"
            	or lexstr == "return" or lexstr == "write"
            	or lexstr == "true"  or lexstr == "while" then
                category = lexit.KEY
            else
                category = lexit.ID
            end
        end
    end

    local function handle_DIGIT()
    	if isDigit(ch) then
            add1()
        elseif ch == "e" or ch == "E" then
            if isDigit(nextChar()) then
                add1()
                state = EXP
            elseif nextChar() == "+" and isDigit(nextNextChar()) then
                add1()
                add1()
                state = EXP
            elseif nextChar() == "-" and isDigit(nextNextChar()) then
                state = DONE
                category = lexit.NUMLIT
            else
                state = DONE
                category = lexit.NUMLIT
            end
        else
            state = DONE
            category = lexit.NUMLIT
        end
	end

    local function handle_EXP()
        if isDigit(ch) then
            add1()
            state = EXP
        else
            state = DONE
            category = lexit.NUMLIT
        end
	end

    local function handle_PLUS()
        if isDigit(ch) and not maxMunch() then
            add1()
            state = DIGIT
        else
            state = DONE
            category = lexit.OP
        end
    end

    local function handle_MINUS()
        if isDigit(ch) and not maxMunch() then
            add1()
            state = DIGIT
        else
            state = DONE
            category = lexit.OP
        end
    end

    local function handle_OPERATOR()  -- Handle * or / or =
        if ch == "=" then
            add1()
        end
        state = DONE
        category = lexit.OP      
    end	

    local function handle_DOUBLEOPERATOR()
        if ch == "&" or ch=="|" then
            add1()
            state = DONE
            category = lexit.OP
        else
            state = DONE
            category = lexit.PUNCT
        end
    end

    local function handle_STRLIT()
        local closing = ch
        add1()
        while currChar() ~= closing do
            if currChar() == "" or currChar() == "\n" then
                add1()
                state = DONE
                category = lexit.MAL
                return
            end
            add1()
        end
        add1()
        state = DONE
        category = lexit.STRLIT
    end     

    -- ***** Table of State-Handler Functions *****

    handlers = {
        [DONE]=handle_DONE,
        [START]=handle_START,
        [LETTER]=handle_LETTER,
        [DIGIT]=handle_DIGIT,
        [EXP]=handle_EXP,
        [PLUS]=handle_PLUS,
        [MINUS]=handle_MINUS,
        [STAR]=handle_STAR,
        [STRLIT]=handle_STRLIT,
        [OPERATOR]=handle_OPERATOR,
        [DBLOPERATOR]=handle_DOUBLEOPERATOR
    }

    -- ***** Iterator Function *****

    -- getLexeme
    -- Called each time through the for-in loop.
    -- Returns a pair: lexeme-string (string) and category (int), or
    -- nil, nil if no more lexemes.
    local function getLexeme(dummy1, dummy2)
        if pos > program:len() then
            return nil, nil
        end
        lexstr = ""
        state = START
        while state ~= DONE do
            ch = currChar()
            handlers[state]()
            previousCat = category
            previousLex = lexstr
        end

        skipWhitespace()
        return lexstr, category
    end

    -- ***** Body of Function lex *****

    -- Initialize & return the iterator function
    pos = 1
    skipWhitespace()
    return getLexeme, nil, nil
end


-- *********************************************************************
-- Module Table Return
-- *********************************************************************


return lexit