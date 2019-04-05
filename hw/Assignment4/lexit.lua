-- lexit.lua
-- VERSION 3
-- Ian Ferguson for HW#3 for CS331
-- Started: 18 Feb 2019
-- Updated: 19 Feb 2019
-- Much of the code derived from Glenn Chappell's public repository

-- *********************************************************************
-- Module Table Initialization
-- *********************************************************************
local lexit = {}  -- Our module; members are added below
-- *********************************************************************
-- Public Constants
-- *********************************************************************
-- Numeric constants representing lexeme categories
lexit.KEY    = 1
lexit.ID     = 2
lexit.NUMLIT = 3
lexit.STRLIT = 4
lexit.OP     = 5
lexit.PUNCT  = 6
lexit.MAL    = 7
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
-- Our lexer
-- Intended for use in a for-in loop:
--     for lexstr, cat in lexer.lex(program) do
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
    local prevchar
    local prevstr
    local nextstate
    local previousCat
    local previousLex
    -- ***** States *****
    local DONE   = 0
    local START  = 1
    local LETTER = 2
    local DIGIT  = 3
    local STR    = 4
    local PLUS   = 5
    local MINUS  = 6
    local EXP    = 7
    local PIPE   = 8
    local AMP    = 9
    local COMPARISON = 10

    -- ***** Character-Related Utility Functions *****
    -- currChar
    -- Return the current character, at index pos in program. Return
    -- value is a single-character string, or the empty string if pos is
    -- past the end.
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

    local function nextTwoChars()
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
    while true do      -- In whitespace
        while isWhitespace(currChar()) do
            drop1()
        end

        if currChar() ~= "#" then  -- Comment?
            break
        end
        drop1()

        while true do  -- In comment
            if currChar() == "\n" then
                break
            elseif currChar() == "" then  -- End of input?
               return
            end
            drop1()
        end
    end
end
    local function maxMunch()
        return previousCat == lexit.ID
        or previousCat == lexit.NUMLIT
        or previousLex == ")"
        or previousLex == "]"
        or previousLex == "true"
        or previousLex == "false"
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
            strQuote = ch
            add1()
            state = STR
        elseif ch == "&" then
            add1()
            state = AMP
        elseif ch == "|" then
            add1()
            state = PIPE
        elseif (ch == "*" or ch == "/" or ch == "%" or ch == "[" or ch == "]") or (ch == "=" and nextChar() ~= "=") then
            add1()
            state = DONE
            category = lexit.OP    
        elseif  ch == "!" or ch == "=" or ch == "<" or ch == ">" then
            add1()
            state = COMPARISON
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
            if lexstr == "begin" or lexstr == "end"
              or lexstr == "print" or lexstr == "cr" or lexstr == "def"
              or lexstr == "else" or lexstr == "elseif" or lexstr == "end"
              or lexstr == "false" or lexstr == "if" or lexstr == "readnum"
              or lexstr == "return" or lexstr == "true" or lexstr == "while"
              or lexstr == "write" then
                category = lexit.KEY
            else
                category = lexit.ID
            end
        end
    end
    local function handle_DIGIT()
        if isDigit(ch) then
            add1()
        elseif ch == "E" or ch == "e" then
            if isDigit(nextChar()) then
                add1()
                add1()
                state = EXP
            elseif nextChar() == "+" then
                if isDigit(nextTwoChars()) then
                    add1()
                    add1()
                    add1()
                    state = EXP
                else
                    state = DONE
                    category = lexit.NUMLIT
                end
            else
                state = DONE
                category = lexit.NUMLIT
            end
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

    local function handle_EXP()
        if isDigit(ch) then
            add1()
            state = EXP
        else
            state = DONE
            category = lexit.NUMLIT
        end
    end

    local function handle_STR()
        if ch == strQuote then
            add1()
            state = DONE 
            category = lexit.STRLIT
        elseif ch ~= "\n" and ch ~= "" then
            add1()
            state = STR
        else 
            add1()
            state = DONE
            category = lexit.MAL
        end
    end
    local function handle_PIPE()
    if ch == "|" then
        add1()
        state = DONE
        category = lexit.OP
    else
        state = DONE 
        category = lexit.PUNCT
      end
    end

   local function handle_COMPARISON()
     if ch == "<" then
        state = DONE
     elseif ch == "=" then
        add1()
        state = DONE
        category = lexit.OP
     else
       state = DONE
       category = lexit.OP
    end
  end
  
  local function handle_AMP()
  if ch == "&" then
    add1()
    state = DONE
    category = lexit.OP
  else
    state = DONE 
    category = lexit.PUNCT
  end
end



    -- ***** Table of State-Handler Functions *****
    handlers = {
        [DONE]=handle_DONE,
        [START]=handle_START,
        [LETTER]=handle_LETTER,
        [DIGIT]=handle_DIGIT,
        [PLUS]=handle_PLUS,
        [MINUS]=handle_MINUS,
        [EXP] =handle_EXP,
        [AMP] =handle_AMP,
        [PIPE] =handle_PIPE,
        [COMPARISON] =handle_COMPARISON,
        [STR] = handle_STR
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
        end
        skipWhitespace()
        previousLex = lexstr
        previousCat = category
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