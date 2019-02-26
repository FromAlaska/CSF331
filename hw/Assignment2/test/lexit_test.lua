#!/usr/bin/env lua
-- lexit_test.lua
-- Glenn G. Chappell
-- 13 Feb 2019
--
-- For CS F331 / CSCE A331 Spring 2019
-- Test Program for Module lexit
-- Used in Assignment 3, Exercise B

lexit = require "lexit"  -- Import lexit module


-- *********************************************
-- * YOU MAY WISH TO CHANGE THE FOLLOWING LINE *
-- *********************************************

EXIT_ON_FIRST_FAILURE = true
-- If EXIT_ON_FIRST_FAILURE is true, then this program exits after the
-- first failing test. If it is false, then this program executes all
-- tests, reporting success/failure for each.


-- *********************************************************************
-- Testing Package
-- *********************************************************************


tester = {}
tester.countTests = 0
tester.countPasses = 0

function tester.test(self, success, testName)
    self.countTests = self.countTests+1
    io.write("    Test: " .. testName .. " - ")
    if success then
        self.countPasses = self.countPasses+1
        io.write("passed")
    else
        io.write("********** FAILED **********")
    end
    io.write("\n")
end

function tester.allPassed(self)
    return self.countPasses == self.countTests
end


-- *********************************************************************
-- Utility Functions
-- *********************************************************************


function fail_exit()
    if EXIT_ON_FIRST_FAILURE then
        io.write("**************************************************\n")
        io.write("* This test program is configured to exit after  *\n")
        io.write("* the first failing test. To make it execute all *\n")
        io.write("* tests, reporting success/failure for each, set *\n")
        io.write("* variable                                       *\n")
        io.write("*                                                *\n")
        io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
        io.write("*                                                *\n")
        io.write("* to false, near the start of the test program.  *\n")
        io.write("**************************************************\n")

        -- Wait for user
        io.write("\nPress ENTER to quit ")
        io.read("*l")

        -- Terminate program
        os.exit(1)
    end
end


-- printTable
-- Given a table, prints it in (roughly) Lua literal notation. If
-- parameter is not a table, prints <not a table>.
function printTable(t)
    -- out
    -- Print parameter, surrounded by double quotes if it is a string,
    -- or simply an indication of its type, if it is not number, string,
    -- or boolean.
    local function out(p)
        if type(p) == "number" then
            io.write(p)
        elseif type(p) == "string" then
            io.write('"'..p..'"')
        elseif type(p) == "boolean" then
            if p then
                io.write("true")
            else
                io.write("false")
            end
        else
            io.write('<'..type(p)..'>')
        end
    end

    if type(t) ~= "table" then
        io.write("<not a table>")
    end

    io.write("{ ")
    local first = true  -- First iteration of loop?
    for k, v in pairs(t) do
        if first then
            first = false
        else
            io.write(", ")
        end
        io.write("[")
        out(k)
        io.write("]=")
        out(v)
    end
    io.write(" }")
end


-- printArray
-- Given a table, prints it in (roughly) Lua literal notation for an
-- array. If parameter is not a table, prints <not a table>.
function printArray(t)
    -- out
    -- Print parameter, surrounded by double quotes if it is a string.
    local function out(p)
        if type(p) == "string" then io.write('"') end
        io.write(p)
        if type(p) == "string" then io.write('"') end
    end

    if type(t) ~= "table" then
        io.write("<not a table>")
    end

    io.write("{ ")
    local first = true  -- First iteration of loop?
    for k, v in ipairs(t) do
        if first then
            first = false
        else
            io.write(", ")
        end
        out(v)
    end
    io.write(" }")
end


-- tableEq
-- Compare equality of two tables.
-- Uses "==" on table values. Returns false if either of t1 or t2 is not
-- a table.
function tableEq(t1, t2)
    -- Both params are tables?
    local type1, type2 = type(t1), type(t2)
    if type1 ~= "table" or type2 ~= "table" then
        return false
    end

    -- Get number of keys in t1 & check values in t1, t2 are equal
    local t1numkeys = 0
    for k, v in pairs(t1) do
        t1numkeys = t1numkeys + 1
        if t2[k] ~= v then
            return false
        end
    end

    -- Check number of keys in t1, t2 same
    local t2numkeys = 0
    for k, v in pairs(t2) do
        t2numkeys = t2numkeys + 1
    end
    return t1numkeys == t2numkeys
end


-- *********************************************************************
-- Definitions for This Test Program
-- *********************************************************************


-- Lexeme Categories
-- Names differ from those in assignment, to avoid interference.
KEYx = 1
IDx = 2
NUMLITx = 3
STRLITx = 4
OPx = 5
PUNCTx = 6
MALx = 7


function checkLex(t, prog, expectedOutput, testName)
    local function printResults(output)
        local blank = " "
        local i = 1
        while i*2 <= #output do
            local lexstr = '"'..output[2*i-1]..'"'
            local lexlen = lexstr:len()
            if lexlen < 8 then
                lexstr = lexstr..blank:rep(8-lexlen)
            end
            local catname = lexit.catnames[output[2*i]]
            print(lexstr, catname)
            i = i+1
        end
    end

    local actualOutput = {}

    local count = 1

    for lexstr, cat in lexit.lex(prog) do
        table.insert(actualOutput, lexstr)
        table.insert(actualOutput, cat)
        count = count+1
    end

    local success = tableEq(actualOutput, expectedOutput)
    t:test(success, testName)
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("Input for the last test above:\n")
        io.write('"'..prog..'"\n')
        io.write("\n")
        io.write("Expected output of lexit.lex:\n")
        printResults(expectedOutput)
        io.write("\n")
        io.write("Actual output of lexit.lex:\n")
        printResults(actualOutput)
        io.write("\n")
        fail_exit()
   end
end


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_export(t)
    io.write("Test Suite: Exported items\n")
    local success

    success = type(lexit) == "table"
    t:test(success, "lexit is a table")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit is undefined or is not a table.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.KEY == KEYx
    t:test(success, "Value of lexit.KEY")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.KEY is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.ID == IDx
    t:test(success, "Value of lexit.ID")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.ID is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.NUMLIT == NUMLITx
    t:test(success, "Value of lexit.NUMLIT")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.NUMLIT is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.STRLIT == STRLITx
    t:test(success, "Value of lexit.STRLIT")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.STRLIT is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.OP == OPx
    t:test(success, "Value of lexit.OP")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.OP is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.PUNCT == PUNCTx
    t:test(success, "Value of lexit.PUNCT")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.PUNCT is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = lexit.MAL == MALx
    t:test(success, "Value of lexit.MAL")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.MAL is undefined or has the wrong value.\n")
        io.write("\n")
        fail_exit()
    end

    success = type(lexit.catnames) == "table"
    t:test(success, "lexit.catnames is a table")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.catnames is undefined or is not a table.\n")
        io.write("\n")
        fail_exit()
    end

    local catnamesx = {
        [KEYx]="Keyword",
        [IDx]="Identifier",
        [NUMLITx]="NumericLiteral",
        [STRLITx]="StringLiteral",
        [OPx]="Operator",
        [PUNCTx]="Punctuation",
        [MALx]="Malformed",
        }
    success = tableEq(catnamesx,lexit.catnames)
    t:test(success, "Value of lexit.catnames")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("Array lexit.catnames does not have the required\n")
        io.write("values. See the assignment description, where the\n")
        io.write("proper values are listed in a table.\n")
        io.write("\n")
        fail_exit()
    end

    success = type(lexit.lex) == "function"
    t:test(success, "lexit.lex is a function")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("lexit.lex is undefined or is not a function.\n")
        io.write("\n")
        fail_exit()
    end

    local keycount = 0
    for k,v in pairs(lexit) do
        keycount = keycount+1
    end
    success = keycount <= 9
    t:test(success, "No extra items exported")
    if EXIT_ON_FIRST_FAILURE and not success then
        io.write("\n")
        io.write("Extra items are exported.\n")
        io.write("That is, table lexit contains extra keys.\n")
        io.write("\n")
        fail_exit()
    end
end

function test_idkey(t)
    io.write("Test Suite: Identifier &amp; Keyword\n")

    checkLex(t, "a", {"a",IDx}, "letter")
    checkLex(t, " a", {"a",IDx}, "space + letter")
    checkLex(t, "_", {"_",IDx}, "underscore")
    checkLex(t, " _", {"_",IDx}, "space + underscore")
    checkLex(t, "bx", {"bx",IDx}, "letter + letter")
    checkLex(t, "b3", {"b3",IDx}, "letter + digit")
    checkLex(t, "_n", {"_n",IDx}, "underscore + letter")
    checkLex(t, "_4", {"_4",IDx}, "underscore + digit")
    checkLex(t, "abc_39xyz", {"abc_39xyz",IDx},
      "medium-length Identifier")
    checkLex(t, "abc def_3", {"abc",IDx,"def_3",IDx},
      "Identifier + Identifier")
    checkLex(t, "a  ", {"a",IDx}, "single letter + space")
    checkLex(t, "a#", {"a",IDx}, "single letter + comment")
    checkLex(t, "a #", {"a",IDx}, "single letter + space + comment")
    checkLex(t, " a", {"a",IDx}, "space + letter")
    checkLex(t, "#\na", {"a",IDx}, "comment + letter")
    checkLex(t, "#\n a", {"a",IDx}, "comment + space + letter")
    checkLex(t, "ab", {"ab",IDx}, "two letters")
    checkLex(t, "cr", {"cr",KEYx}, "keyword: cr")
    checkLex(t, "def", {"def",KEYx}, "keyword: def")
    checkLex(t, "else", {"else",KEYx}, "keyword: else")
    checkLex(t, "elseif", {"elseif",KEYx}, "keyword: elseif")
    checkLex(t, "end", {"end",KEYx}, "keyword: end")
    checkLex(t, "false", {"false",KEYx}, "keyword: false")
    checkLex(t, "if", {"if",KEYx}, "keyword: if")
    checkLex(t, "readnum", {"readnum",KEYx}, "keyword: readnum")
    checkLex(t, "return", {"return",KEYx}, "keyword: return")
    checkLex(t, "true", {"true",KEYx}, "keyword: true")
    checkLex(t, "while", {"while",KEYx}, "keyword: while")
    checkLex(t, "write", {"write",KEYx}, "keyword: write")
    checkLex(t, "ends", {"ends",IDx}, "keyword+letter")
    checkLex(t, "while2", {"while2",IDx}, "keyword+digit")
    checkLex(t, "elsE", {"elsE",IDx}, "keyword -> 1 letter UC")
    checkLex(t, "DEF", {"DEF",IDx}, "keyword -> all UC")
    checkLex(t, "read num",{"read",IDx,"num",IDx},"split keyword #1")
    checkLex(t, "elsei",{"elsei",IDx},"partial keyword")
    checkLex(t, "tr#\nue",{"tr",IDx,"ue",IDx},"split keyword #2")
    checkLex(t, "fal2se",{"fal2se",IDx},"split keyword #3")
    checkLex(t, "wri_te",{"wri_te",IDx},"split keyword #4")
    checkLex(t, "else if",{"else",KEYx,"if",KEYx},"split keyword #5")
    checkLex(t, "_while",{"_while",IDx},"_ + keyword")
    local astr = "a"
    local longid = astr:rep(10000)
    checkLex(t, longid,{longid,IDx}, "long id")
end


function test_numlit(t)
    io.write("Test Suite: NumericLiteral\n")

    checkLex(t, "3", {"3",NUMLITx}, "single digit")
    checkLex(t, "3a", {"3",NUMLITx,"a",IDx}, "single digit then letter")

    checkLex(t, "123456", {"123456",NUMLITx}, "num, no dot")
    checkLex(t, ".123456", {".",PUNCTx,"123456",NUMLITx},
             "num, dot @ start")
    checkLex(t, "123456.", {"123456",NUMLITx,".",PUNCTx},
             "num, dot @ end")
    checkLex(t, "123.456", {"123",NUMLITx,".",PUNCTx,"456",NUMLITx},
             "num, dot in middle")
    checkLex(t, "1.2.3", {"1",NUMLITx,".",PUNCTx,"2",NUMLITx,".",PUNCTx,
                          "3",NUMLITx}, "num, 2 dots")

    checkLex(t, "+123456", {"+123456",NUMLITx}, "+num, no dot")
    checkLex(t, "+.123456", {"+",OPx,".",PUNCTx,"123456",NUMLITx},
             "+num, dot @ start")
    checkLex(t, "+123456.", {"+123456",NUMLITx,".",PUNCTx},
             "+num, dot @ end")
    checkLex(t, "+123.456", {"+123",NUMLITx,".",PUNCTx,"456",NUMLITx},
             "+num, dot in middle")
    checkLex(t, "+1.2.3", {"+1",NUMLITx,".",PUNCTx,"2",NUMLITx,
                           ".",PUNCTx,"3",NUMLITx}, "+num, 2 dots")

    checkLex(t, "-123456", {"-123456",NUMLITx}, "-num, no dot")
    checkLex(t, "-.123456", {"-",OPx,".",PUNCTx,"123456",NUMLITx},
             "-num, dot @ start")
    checkLex(t, "-123456.", {"-123456",NUMLITx,".",PUNCTx},
             "-num, dot @ end")
    checkLex(t, "-123.456", {"-123",NUMLITx,".",PUNCTx,"456",NUMLITx},
             "-num, dot in middle")
    checkLex(t, "-1.2.3", {"-1",NUMLITx,".",PUNCTx,"2",NUMLITx,
                           ".",PUNCTx,"3",NUMLITx}, "-num, 2 dots")

    checkLex(t, "--123456", {"-",OPx,"-123456",NUMLITx},
             "--num, no dot")
    checkLex(t, "--123456", {"-",OPx,"-123456",NUMLITx},
             "--num, dot @ end")

    local onestr = "1"
    local longnumstr = onestr:rep(10000)
    checkLex(t, longnumstr, {longnumstr,NUMLITx}, "very long num #1")
    checkLex(t, longnumstr.."+", {longnumstr,NUMLITx,"+",OPx},
             "very long num #2")
    checkLex(t, "123 456", {"123",NUMLITx,"456",NUMLITx},
             "space-separated nums")

    -- Exponents
    checkLex(t, "123e456", {"123e456",NUMLITx}, "num with exp")
    checkLex(t, "123e+456", {"123e+456",NUMLITx}, "num with +exp")
    checkLex(t, "123e-456", {"123",NUMLITx,"e",IDx,"-",OPx,
                             "456",NUMLITx}, "num with -exp")
    checkLex(t, "+123e456", {"+123e456",NUMLITx}, "+num with exp")
    checkLex(t, "+123e+456", {"+123e+456",NUMLITx}, "+num with +exp")
    checkLex(t, "+123e-456", {"+123",NUMLITx,"e",IDx,"-",OPx,
                              "456",NUMLITx}, "+num with -exp")
    checkLex(t, "-123e456", {"-123e456",NUMLITx}, "-num with exp")
    checkLex(t, "-123e+456", {"-123e+456",NUMLITx}, "-num with +exp")
    checkLex(t, "-123e-456", {"-123",NUMLITx,"e",IDx,"-",OPx,
                              "456",NUMLITx}, "-num with -exp")
    checkLex(t, "123E456", {"123E456",NUMLITx}, "num with Exp")
    checkLex(t, "123E+456", {"123E+456",NUMLITx}, "num with +Exp")
    checkLex(t, "123E-456", {"123",NUMLITx,"E",IDx,"-",OPx,
                             "456",NUMLITx}, "num with -Exp")
    checkLex(t, "+123E456", {"+123E456",NUMLITx}, "+num with Exp")
    checkLex(t, "+123E+456", {"+123E+456",NUMLITx}, "+num with +Exp")
    checkLex(t, "+123E-456", {"+123",NUMLITx,"E",IDx,"-",OPx,
                              "456",NUMLITx}, "+num with -Exp")
    checkLex(t, "-123E456", {"-123E456",NUMLITx}, "-num with Exp")
    checkLex(t, "-123E+456", {"-123E+456",NUMLITx}, "-num with +Exp")
    checkLex(t, "-123E-456", {"-123",NUMLITx,"E",IDx,"-",OPx,
                              "456",NUMLITx}, "-num with -Exp")

    checkLex(t, "1.2e34", {"1",NUMLITx,".",PUNCTx,"2e34",NUMLITx},
             "num with dot, exp")
    checkLex(t, "12e3.4", {"12e3",NUMLITx,".",PUNCTx,"4",NUMLITx},
             "num, exp with dot")

    checkLex(t, "e", {"e",IDx}, "Just e")
    checkLex(t, "E", {"E",IDx}, "Just E")
    checkLex(t, "e3", {"e3",IDx}, "e3")
    checkLex(t, "E3", {"E3",IDx}, "E3")
    checkLex(t, "e+3", {"e",IDx,"+",OPx,"3",NUMLITx}, "e+3")
    checkLex(t, "E+3", {"E",IDx,"+",OPx,"3",NUMLITx}, "E+3")
    checkLex(t, "1e3", {"1e3",NUMLITx}, "1e3")
    checkLex(t, "123e", {"123",NUMLITx,"e",IDx}, "num e")
    checkLex(t, "123E", {"123",NUMLITx,"E",IDx}, "num E")
    checkLex(t, "123ee", {"123",NUMLITx,"ee",IDx}, "num ee #1")
    checkLex(t, "123Ee", {"123",NUMLITx,"Ee",IDx}, "num ee #2")
    checkLex(t, "123eE", {"123",NUMLITx,"eE",IDx}, "num ee #3")
    checkLex(t, "123EE", {"123",NUMLITx,"EE",IDx}, "num ee #4")
    checkLex(t, "123ee1", {"123",NUMLITx,"ee1",IDx}, "num ee num #1")
    checkLex(t, "123Ee1", {"123",NUMLITx,"Ee1",IDx}, "num ee num #2")
    checkLex(t, "123eE1", {"123",NUMLITx,"eE1",IDx}, "num ee num #3")
    checkLex(t, "123EE1", {"123",NUMLITx,"EE1",IDx}, "num ee num #4")
    checkLex(t, "123e+", {"123",NUMLITx,"e",IDx,"+",OPx}, "num e+ #1")
    checkLex(t, "123E+", {"123",NUMLITx,"E",IDx,"+",OPx}, "num e+ #2")
    checkLex(t, "123e-", {"123",NUMLITx,"e",IDx,"-",OPx}, "num e- #1")
    checkLex(t, "123E-", {"123",NUMLITx,"E",IDx,"-",OPx}, "num e- #2")
    checkLex(t, "123e+e7", {"123",NUMLITx,"e",IDx,"+",OPx,"e7",IDx},
             "num e+e7")
    checkLex(t, "123e-e7", {"123",NUMLITx,"e",IDx,"-",OPx,"e7",IDx},
             "num e-e7")
    checkLex(t, "123e7e", {"123e7",NUMLITx,"e",IDx}, "num e7e")
    checkLex(t, "123e+7e", {"123e+7",NUMLITx,"e",IDx}, "num e+7e")
    checkLex(t, "123e-7e", {"123",NUMLITx,"e",IDx,"-",OPx,"7",NUMLITx,
                            "e",IDx}, "num e-7e")
    checkLex(t, "123f7", {"123",NUMLITx,"f7",IDx}, "num f7 #1")
    checkLex(t, "123F7", {"123",NUMLITx,"F7",IDx}, "num f7 #2")

    checkLex(t, "123 e+7", {"123",NUMLITx,"e",IDx,"+",OPx,"7",NUMLITx},
             "space-separated exp #1")
    checkLex(t, "123 e-7", {"123",NUMLITx,"e",IDx,"-",OPx,"7",NUMLITx},
             "space-separated exp #2")
    checkLex(t, "123e1 2", {"123e1",NUMLITx,"2",NUMLITx},
             "space-separated exp #3")
    checkLex(t, "123end", {"123",NUMLITx,"end",KEYx},
             "number end")
    checkLex(t, "1e2e3", {"1e2",NUMLITx,"e3",IDx},
             "number exponent #1")
    checkLex(t, "1e+2e3", {"1e+2",NUMLITx,"e3",IDx},
             "number exponent #2")
    checkLex(t, "1e-2e3", {"1",NUMLITx,"e",IDx,"-",OPx,"2e3",NUMLITx},
             "number exponent #3")

    twostr = "2"
    longexp = twostr:rep(10000)
    checkLex(t, "3e"..longexp, {"3e"..longexp,NUMLITx}, "long exp #1")
    checkLex(t, "3e"..longexp.."-", {"3e"..longexp,NUMLITx,"-",OPx},
             "long exp #2")
end


function test_strlit(t)
    io.write("Test Suite: StringLiteral\n")

    checkLex(t, "''", {"''",STRLITx}, "Empty single-quoted str")
    checkLex(t, "\"\"", {"\"\"",STRLITx}, "Empty double-quoted str")
    checkLex(t, "'a'", {"'a'",STRLITx}, "1-char single-quoted str")
    checkLex(t, "\"b\"", {"\"b\"",STRLITx}, "1-char double-quoted str")
    checkLex(t, "'abc def'", {"'abc def'",STRLITx},
             "longer single-quoted str")
    checkLex(t, "\"The quick brown fox.\"",
             {"\"The quick brown fox.\"",STRLITx},
             "longer double-quoted str")
    checkLex(t, "'aa\"bb'", {"'aa\"bb'",STRLITx},
             "single-quoted str with double quote")
    checkLex(t, "\"cc'dd\"", {"\"cc'dd\"",STRLITx},
             "double-quoted str with single quote")
    checkLex(t, "'aabbcc", {"'aabbcc",MALx},
             "partial single-quoted str #1")
    checkLex(t, "'aabbcc\"", {"'aabbcc\"",MALx},
             "partial single-quoted str #2")
    checkLex(t, "'aabbcc\n", {"'aabbcc\n",MALx},
             "partial single-quoted str #3")
    checkLex(t, "\"aabbcc", {"\"aabbcc",MALx},
             "partial double-quoted str #1")
    checkLex(t, "\"aabbcc'", {"\"aabbcc'",MALx},
             "partial double-quoted str #2")
    checkLex(t, "\"aabbcc\n", {"\"aabbcc\n",MALx},
             "partial double-quoted str #3")
    checkLex(t, "'\"'\"'\"", {"'\"'",STRLITx,"\"'\"",STRLITx},
             "multiple strs")
    checkLex(t, "'#'#'\n'\n'", {"'#'",STRLITx,"'\n",MALx,"'",MALx},
             "strs & comments")
    checkLex(t, "\"a\"a\"a\"a\"",
             {"\"a\"",STRLITx,"a",IDx,"\"a\"",STRLITx,"a",IDx,
              "\"",MALx},"strs & identifiers")
    xstr = "x"
    longstr = "'"..xstr:rep(10000).."'"
    checkLex(t, "a"..longstr.."b", {"a",IDx,longstr,STRLITx,"b",IDx},
             "very long str")
end


function test_op(t)
    io.write("Test Suite: Operator\n")

    -- Operator alone
    checkLex(t, "&&", {"&&",OPx}, "&& alone")
    checkLex(t, "||", {"||",OPx}, "|| alone")
    checkLex(t, "!",  {"!",OPx},  "! alone")
    checkLex(t, "==", {"==",OPx}, "== alone")
    checkLex(t, "!=", {"!=",OPx}, "!= alone")
    checkLex(t, "<",  {"<",OPx},  "< alone")
    checkLex(t, "<=", {"<=",OPx}, "<= alone")
    checkLex(t, ">",  {">",OPx},  "> alone")
    checkLex(t, ">=", {">=",OPx}, ">= alone")
    checkLex(t, "+",  {"+",OPx},  "+ alone")
    checkLex(t, "-",  {"-",OPx},  "- alone")
    checkLex(t, "*",  {"*",OPx},  "* alone")
    checkLex(t, "/",  {"/",OPx},  "/ alone")
    checkLex(t, "%",  {"%",OPx},  "% alone")
    checkLex(t, "[",  {"[",OPx},  "[ alone")
    checkLex(t, "]",  {"]",OPx},  "] alone")
    checkLex(t, "=",  {"=",OPx},  "= alone")

    -- Operator followed by digit
    checkLex(t, "&&1", {"&&",OPx,"1",NUMLITx}, "&& 1")
    checkLex(t, "||1", {"||",OPx,"1",NUMLITx}, "|| 1")
    checkLex(t, "!1",  {"!",OPx,"1",NUMLITx},  "! 1")
    checkLex(t, "==1", {"==",OPx,"1",NUMLITx}, "== 1")
    checkLex(t, "!=1", {"!=",OPx,"1",NUMLITx}, "!= 1")
    checkLex(t, "<1",  {"<",OPx,"1",NUMLITx},  "< 1")
    checkLex(t, "<=1", {"<=",OPx,"1",NUMLITx}, "<= 1")
    checkLex(t, ">1",  {">",OPx,"1",NUMLITx},  "> 1")
    checkLex(t, ">=1", {">=",OPx,"1",NUMLITx}, ">= 1")
    checkLex(t, "+1",  {"+1",NUMLITx},  "+ 1")
    checkLex(t, "-1",  {"-1",NUMLITx},  "- 1")
    checkLex(t, "*1",  {"*",OPx,"1",NUMLITx},  "* 1")
    checkLex(t, "/1",  {"/",OPx,"1",NUMLITx},  "/ 1")
    checkLex(t, "%1",  {"%",OPx,"1",NUMLITx},  "% 1")
    checkLex(t, "[1",  {"[",OPx,"1",NUMLITx},  "[ 1")
    checkLex(t, "]1",  {"]",OPx,"1",NUMLITx},  "] 1")
    checkLex(t, "=1",  {"=",OPx,"1",NUMLITx},  "= 1")

    -- Operator followed by letter
    checkLex(t, "&&a", {"&&",OPx,"a",IDx}, "&& a")
    checkLex(t, "||a", {"||",OPx,"a",IDx}, "|| a")
    checkLex(t, "!a",  {"!",OPx,"a",IDx},  "! a")
    checkLex(t, "==a", {"==",OPx,"a",IDx}, "== a")
    checkLex(t, "!=a", {"!=",OPx,"a",IDx}, "!= a")
    checkLex(t, "<a",  {"<",OPx,"a",IDx},  "< a")
    checkLex(t, "<=a", {"<=",OPx,"a",IDx}, "<= a")
    checkLex(t, ">a",  {">",OPx,"a",IDx},  "> a")
    checkLex(t, ">=a", {">=",OPx,"a",IDx}, ">= a")
    checkLex(t, "+a",  {"+",OPx,"a",IDx},  "+ a")
    checkLex(t, "-a",  {"-",OPx,"a",IDx},  "- a")
    checkLex(t, "*a",  {"*",OPx,"a",IDx},  "* a")
    checkLex(t, "/a",  {"/",OPx,"a",IDx},  "/ a")
    checkLex(t, "%a",  {"%",OPx,"a",IDx},  "% a")
    checkLex(t, "[a",  {"[",OPx,"a",IDx},  "[ a")
    checkLex(t, "]a",  {"]",OPx,"a",IDx},  "] a")
    checkLex(t, "=a",  {"=",OPx,"a",IDx},  "= a")

    -- Operator followed by "*"
    checkLex(t, "&&*", {"&&",OPx,"*",OPx}, "&& *")
    checkLex(t, "||*", {"||",OPx,"*",OPx}, "|| *")
    checkLex(t, "!*",  {"!",OPx,"*",OPx},  "! *")
    checkLex(t, "==*", {"==",OPx,"*",OPx}, "== *")
    checkLex(t, "!=*", {"!=",OPx,"*",OPx}, "!= *")
    checkLex(t, "<*",  {"<",OPx,"*",OPx},  "< *")
    checkLex(t, "<=*", {"<=",OPx,"*",OPx}, "<= *")
    checkLex(t, ">*",  {">",OPx,"*",OPx},  "> *")
    checkLex(t, ">=*", {">=",OPx,"*",OPx}, ">= *")
    checkLex(t, "+*",  {"+",OPx,"*",OPx},  "+ *")
    checkLex(t, "-*",  {"-",OPx,"*",OPx},  "- *")
    checkLex(t, "**",  {"*",OPx,"*",OPx},  "* *")
    checkLex(t, "/*",  {"/",OPx,"*",OPx},  "/ *")
    checkLex(t, "%*",  {"%",OPx,"*",OPx},  "% *")
    checkLex(t, "[*",  {"[",OPx,"*",OPx},  "[ *")
    checkLex(t, "]*",  {"]",OPx,"*",OPx},  "] *")
    checkLex(t, "=*",  {"=",OPx,"*",OPx},  "= *")

    -- Nonexistents operators
    checkLex(t, "++", {"+",OPx,"+",OPx}, "NOT operator: ++")
    checkLex(t, "++2", {"+",OPx,"+2",NUMLITx}, "NOT operator: ++ digit")
    checkLex(t, "--", {"-",OPx,"-",OPx}, "NOT operator: --")
    checkLex(t, "--2", {"-",OPx,"-2",NUMLITx}, "NOT operator: -- digit")
    checkLex(t, ".", {".",PUNCTx}, "NOT operator: .")
    checkLex(t, "+=", {"+",OPx,"=",OPx}, "NOT operator: +=")
    checkLex(t, "+==", {"+",OPx,"==",OPx}, "NOT operator: += =")
    checkLex(t, "-=", {"-",OPx,"=",OPx}, "NOT operator: -=")
    checkLex(t, "-==", {"-",OPx,"==",OPx}, "NOT operator: -= =")
    checkLex(t, "*=", {"*",OPx,"=",OPx}, "NOT operator: *=")
    checkLex(t, "*==", {"*",OPx,"==",OPx}, "NOT operator: *= =")
    checkLex(t, "/=", {"/",OPx,"=",OPx}, "NOT operator: *=")
    checkLex(t, "/==", {"/",OPx,"==",OPx}, "NOT operator: /= =")
    checkLex(t, ":", {":",PUNCTx}, "NOT operator: :")

    -- Partial operators
    checkLex(t, "&", {"&",PUNCTx}, "partial operator: &")
    checkLex(t, "|", {"|",PUNCTx}, "partial operator: |")

    -- More complex stuff
    checkLex(t, "=====", {"==",OPx,"==",OPx,"=",OPx}, "=====")
    checkLex(t, "=<<==", {"=",OPx,"<",OPx,"<=",OPx,"=",OPx}, "=<<==")
    checkLex(t, "**/ ",  {"*",OPx,"*",OPx,"/",OPx}, "**/ ")
    checkLex(t, "& &",   {"&",PUNCTx,"&",PUNCTx}, "& &")
    checkLex(t, "| |",   {"|",PUNCTx,"|",PUNCTx}, "| |")
    checkLex(t, "= =",   {"=",OPx,"=",OPx}, "= =")
    checkLex(t, "--2-",  {"-",OPx,"-2",NUMLITx,"-",OPx}, "--2-")

    -- Punctuation chars
    checkLex(t, "$(),.:;?@\\^`{}~",
             {"$",PUNCTx,"(",PUNCTx,")",PUNCTx,",",PUNCTx,".",PUNCTx,
              ":",PUNCTx,";",PUNCTx,"?",PUNCTx,"@",PUNCTx,"\\",PUNCTx,
              "^",PUNCTx,"`",PUNCTx,"{",PUNCTx,"}",PUNCTx,"~",PUNCTx},
             "assorted punctuation")
end


function test_illegal(t)
    io.write("Test Suite: Illegal Characters\n")

    checkLex(t, "\001", {"\001",MALx}, "Single illegal character #1")
    checkLex(t, "\031", {"\031",MALx}, "Single illegal character #2")
    checkLex(t, "\001 \002", {"\001",MALx,"\002",MALx},
             "Illegal characters & whitespace")
    checkLex(t, "a\002bcd\003\004ef",
             {"a",IDx,"\002",MALx,"bcd",IDx,"\003",MALx,
              "\004",MALx,"ef",IDx},
             "Various illegal characters")
    checkLex(t, "a#\001\002\nb", {"a",IDx,"b",IDx},
             "Illegal characters in comment")
    checkLex(t, "b'\001\002'", {"b",IDx,"'\001\002'",STRLITx},
             "Illegal characters in single-quoted string")
    checkLex(t, "c\"\001\002\"", {"c",IDx,"\"\001\002\"",STRLITx},
             "Illegal characters in double-quoted string")
    checkLex(t, "b'\001\002", {"b",IDx,"'\001\002",MALx},
             "Illegal characters in single-quoted partial string")
    checkLex(t, "c\"\001\002", {"c",IDx,"\"\001\002",MALx},
             "Illegal characters in double-quoted partial string")
end


function test_comment(t)
    io.write("Test Suite: Space & Comments\n")

    -- Space
    checkLex(t, " ", {}, "Single space character #1")
    checkLex(t, "\t", {}, "Single space character #2")
    checkLex(t, "\n", {}, "Single space character #3")
    checkLex(t, "\r", {}, "Single space character #4")
    checkLex(t, "\f", {}, "Single space character #5")
    checkLex(t, "ab 12", {"ab",IDx,"12",NUMLITx},
             "Space-separated lexemes #1")
    checkLex(t, "ab\t12", {"ab",IDx,"12",NUMLITx},
             "Space-separated lexemes #2")
    checkLex(t, "ab\n12", {"ab",IDx,"12",NUMLITx},
             "Space-separated lexemes #3")
    checkLex(t, "ab\r12", {"ab",IDx,"12",NUMLITx},
             "Space-separated lexemes #4")
    checkLex(t, "ab\f12", {"ab",IDx,"12",NUMLITx},
             "Space-separated lexemes #5")
    blankstr = " "
    longspace = blankstr:rep(10000)
    checkLex(t, longspace.."abc"..longspace, {"abc",IDx},
             "very long space")

    -- Comments
    checkLex(t, "#abcd\n", {}, "Comment")
    checkLex(t, "12#abcd\nab", {"12",NUMLITx,"ab",IDx},
             "Comment-separated lexemes")
    checkLex(t, "12#abcd", {"12",NUMLITx}, "Unterminated comment #1")
    checkLex(t, "12#abcd#", {"12",NUMLITx}, "Unterminated comment #2")
    checkLex(t, "12#a\n#b\n#c\nab", {"12",NUMLITx,"ab",IDx},
             "Multiple comments #1")
    checkLex(t, "12#a\n  #b\n \n #c\nab", {"12",NUMLITx,"ab",IDx},
             "Multiple comments #2")
    checkLex(t, "12#a\n=#b\n.#c\nab",
             {"12",NUMLITx,"=",OPx,".",PUNCTx,"ab",IDx},
             "Multiple comments #3")
    checkLex(t, "a##\nb", {"a",IDx,"b",IDx}, "Comment with # #1")
    checkLex(t, "a##b", {"a",IDx}, "Comment with # #2")
    checkLex(t, "a##b\n\nc", {"a",IDx,"c",IDx}, "Comment with # #3")
    xstr = "x"
    longcmt = "#"..xstr:rep(10000).."\n"
    checkLex(t, "a"..longcmt.."b", {"a",IDx,"b",IDx},
             "very long comment")
end


function test_mmexcept(t)
    io.write("Test Suite: Exception to Maximal-Munch\n")

    checkLex(t, "+123", {"+123",NUMLITx}, "+NUMLIT at start")
    checkLex(t, "-123", {"-123",NUMLITx}, "-NUMLIT at start")
    checkLex(t, "return+123", {"return",KEYx,"+123",NUMLITx},
             "+NUMLIT after keyword")
    checkLex(t, "return-123", {"return",KEYx,"-123",NUMLITx},
             "-NUMLIT after keyword")
    checkLex(t, "abc+123", {"abc",IDx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after identifier")
    checkLex(t, "abc-123", {"abc",IDx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after identifier")
    checkLex(t, "abc +123", {"abc",IDx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after identifier, with space")
    checkLex(t, "abc -123", {"abc",IDx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after identifier, with space")
    checkLex(t, "2+123", {"2",NUMLITx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after number")
    checkLex(t, "2-123", {"2",NUMLITx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after number")
    checkLex(t, "abc-123", {"abc",IDx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after identifier")
    checkLex(t, "[+123", {"[",OPx,"+123",NUMLITx},
             "+NUMLIT after left bracket")
    checkLex(t, "[-123", {"[",OPx,"-123",NUMLITx},
             "-NUMLIT after left bracket")
    checkLex(t, "]+123", {"]",OPx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after right bracket")
    checkLex(t, "]-123", {"]",OPx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after right bracket")
    checkLex(t, "(+123", {"(",PUNCTx,"+123",NUMLITx},
             "+NUMLIT after left paren")
    checkLex(t, "(-123", {"(",PUNCTx,"-123",NUMLITx},
             "-NUMLIT after left paren")
    checkLex(t, ")+123", {")",PUNCTx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after right paren")
    checkLex(t, ")-123", {")",PUNCTx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after right paren")
    checkLex(t, "true+123", {"true",KEYx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after true")
    checkLex(t, "true-123", {"true",KEYx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after true")
    checkLex(t, "false+123", {"false",KEYx,"+",OPx,"123",NUMLITx},
             "+NUMLIT after false")
    checkLex(t, "false-123", {"false",KEYx,"-",OPx,"123",NUMLITx},
             "-NUMLIT after false")
    checkLex(t, "=+123", {"=",OPx,"+123",NUMLITx},
             "+NUMLIT after op")
    checkLex(t, "=-123", {"=",OPx,"-123",NUMLITx},
             "-NUMLIT after op")
    checkLex(t, "'abc'-123", {"'abc'",STRLITx,"-123",NUMLITx},
             "-NUMLIT after string")
    checkLex(t, "'abc'+123", {"'abc'",STRLITx,"+123",NUMLITx},
             "+NUMLIT after string")
    checkLex(t, "abc+123*+123", {"abc",IDx,"+",OPx,"123",NUMLITx,
                                 "*",OPx,"+123",NUMLITx},
             "identifier +NUMLIT op +NUMLIT")
    checkLex(t, "abc-123*-123", {"abc",IDx,"-",OPx,"123",NUMLITx,
                                 "*",OPx,"-123",NUMLITx},
             "identifier -NUMLIT op -NUMLIT")
    checkLex(t, "-1-1-1-1", {"-1",NUMLITx,"-",OPx,"1",NUMLITx,"-",OPx,
                             "1",NUMLITx,"-",OPx,"1",NUMLITx},
             "Repeated -1")
    checkLex(t, "-1-1 -1-1", {"-1",NUMLITx,"-",OPx,"1",NUMLITx,"-",OPx,
                             "1",NUMLITx,"-",OPx,"1",NUMLITx},
             "Repeated -1 with space")
    checkLex(t, "+1+1+1+1", {"+1",NUMLITx,"+",OPx,"1",NUMLITx,"+",OPx,
                             "1",NUMLITx,"+",OPx,"1",NUMLITx},
             "Repeated +1")
    checkLex(t, "+1+1 +1+1", {"+1",NUMLITx,"+",OPx,"1",NUMLITx,"+",OPx,
                             "1",NUMLITx,"+",OPx,"1",NUMLITx},
             "Repeated +1 with space")
    checkLex(t, "++1++1++1++1", {"+",OPx,"+1",NUMLITx,"+",OPx,
                                 "+1",NUMLITx,"+",OPx,"+1",NUMLITx,
                                 "+",OPx,"+1",NUMLITx},
             "Repeated ++1")
    checkLex(t, "(k-4)+-7*+3", {"(",PUNCTx,"k",IDx,"-",OPx,"4",NUMLITx,
                                ")",PUNCTx,"+",OPx,"-7",NUMLITx,"*",OPx,
                                "+3",NUMLITx},
             "code snippet #1")
    checkLex(t, "write(-4*-4-4)return-3+3+k+3-(+3)",
             {"write",KEYx,"(",PUNCTx,"-4",NUMLITx,"*",OPx,"-4",NUMLITx,
              "-",OPx,"4",NUMLITx,")",PUNCTx,"return",KEYx,"-3",NUMLITx,
              "+",OPx,"3",NUMLITx,"+",OPx,"k",IDx,"+",OPx,"3",NUMLITx,
              "-",OPx,"(",PUNCTx,"+3",NUMLITx,")",PUNCTx},
             "code snippet #2")
end


function test_program(t)
    io.write("Test Suite: Complete Programs\n")

    -- Short program, little whitespace
    checkLex(t, "a_1[0]=1"..
                "a_1[a_1[0]]=a_1[0]+2"..
                "_b2b=a_1[0]+3"..
                "if _b2b==6write('good',cr)"..
                "elseif _b2b>6write('too high',cr)"..
                "else write('too low',cr)"..
                "end",
             {"a_1",IDx,"[",OPx,"0",NUMLITx,"]",OPx,"=",OPx,"1",NUMLITx,
              "a_1",IDx,"[",OPx,"a_1",IDx,"[",OPx,"0",NUMLITx,"]",OPx,
                "]",OPx,"=",OPx,"a_1",IDx,"[",OPx,"0",NUMLITx,"]",OPx,
                "+",OPx,"2",NUMLITx,
              "_b2b",IDx,"=",OPx,"a_1",IDx,"[",OPx,"0",NUMLITx,"]",OPx,
                "+",OPx,"3",NUMLITx,
              "if",KEYx,"_b2b",IDx,"==",OPx,"6",NUMLITx,"write",KEYx,
                "(",PUNCTx,"'good'",STRLITx,",",PUNCTx,"cr",KEYx,
                ")",PUNCTx,
              "elseif",KEYx,"_b2b",IDx,">",OPx,"6",NUMLITx,"write",KEYx,
                "(",PUNCTx,"'too high'",STRLITx,",",PUNCTx,"cr",KEYx,
                ")",PUNCTx,
              "else",KEYx,"write",KEYx,"(",PUNCTx,"'too low'",STRLITx,
                ",",PUNCTx,
                "cr",KEYx,")",PUNCTx,
              "end",KEYx},
              "Short program, little whitespace")

    -- Program from slides
    checkLex(t, "# Function fibo\n"..
                "# Given k, return F(k), where\n"..
                "# F(n) = nth Fibonacci no.\n"..
                "def fibo()\n"..
                "    a = 0  # Consecutive Fibos\n"..
                "    b = 1\n"..
                "    i = 0  # Loop counter\n"..
                "    while i < k\n"..
                "        c = a+b  # Advance\n"..
                "        a = b\n"..
                "        b = c\n"..
                "        i = i+1  # ++counter\n"..
                "    end\n"..
                "    return a     # Result\n"..
                "end\n"..
                "\n"..
                "# Main Program\n"..
                "\n"..
                "# Get number of Fibos to output\n"..
                "write(\"How many Fibos to print? \")\n"..
                "n = readnum()\n"..
                "write(cr)\n"..
                "\n"..
                "# Print requested number of Fibos\n"..
                "j = 0  # Loop counter\n"..
                "while j < n\n"..
                "    k = j\n"..
                "    write(\"F(\",j,\") = \",fibo(),cr)\n"..
                "    j = j+1  # ++counter\n"..
                "end\n",
             {"def",KEYx,"fibo",IDx,"(",PUNCTx,")",PUNCTx,
              "a",IDx,"=",OPx,"0",NUMLITx,
              "b",IDx,"=",OPx,"1",NUMLITx,
              "i",IDx,"=",OPx,"0",NUMLITx,
              "while",KEYx,"i",IDx,"<",OPx,"k",IDx,
              "c",IDx,"=",OPx,"a",IDx,"+",OPx,"b",IDx,
              "a",IDx,"=",OPx,"b",IDx,
              "b",IDx,"=",OPx,"c",IDx,
              "i",IDx,"=",OPx,"i",IDx,"+",OPx,"1",NUMLITx,
              "end",KEYx,
              "return",KEYx,"a",IDx,
              "end",KEYx,
              "write",KEYx,"(",PUNCTx,
              "\"How many Fibos to print? \"",STRLITx,")",PUNCTx,
              "n",IDx,"=",OPx,"readnum",KEYx,"(",PUNCTx,")",PUNCTx,
              "write",KEYx,"(",PUNCTx,"cr",KEYx,")",PUNCTx,
              "j",IDx,"=",OPx,"0",NUMLITx,
              "while",KEYx,"j",IDx,"<",OPx,"n",IDx,
              "k",IDx,"=",OPx,"j",IDx,
              "write",KEYx,"(",PUNCTx,"\"F(\"",STRLITx,",",PUNCTx,
                "j",IDx,",",PUNCTx,"\") = \"",STRLITx,",",PUNCTx,
                "fibo",IDx,"(",PUNCTx,")",PUNCTx,",",PUNCTx,"cr",KEYx,
                ")",PUNCTx,
              "j",IDx,"=",OPx,"j",IDx,"+",OPx,"1",NUMLITx,
              "end",KEYx},
              "Program from slides")

    -- Program with other lexemes, little whitespace
    checkLex(t, "if!(true&&false||1)<2<=3>4>=5-6*7/8%9+a[3]"..
                "abcdefg_12345=00000"..
                "write+123e45--987E+65+abcdefg_12345 "..
                "end",
             {"if",KEYx,"!",OPx,"(",PUNCTx,"true",KEYx,"&&",OPx,
              "false",KEYx,"||",OPx,"1",NUMLITx,")",PUNCTx,"<",OPx,
              "2",NUMLITx,"<=",OPx,"3",NUMLITx,">",OPx,"4",NUMLITx,
              ">=",OPx,"5",NUMLITx,"-",OPx,"6",NUMLITx,"*",OPx,
              "7",NUMLITx,"/",OPx,"8",NUMLITx,"%",OPx,"9",NUMLITx,
              "+",OPx,"a",IDx,"[",OPx,"3",NUMLITx,"]",OPx,
              "abcdefg_12345",IDx,"=",OPx,"00000",NUMLITx,"write",KEYx,
              "+123e45",NUMLITx,"-",OPx,"-987E+65",NUMLITx,"+",OPx,
              "abcdefg_12345",IDx,"end",KEYx},
             "Program with other lexemes, little whitespace")
end


function test_lexit(t)
    io.write("TEST SUITES FOR MODULE lexit\n")
    test_export(t)
    test_idkey(t)
    test_numlit(t)
    test_strlit(t)
    test_op(t)
    test_illegal(t)
    test_comment(t)
    test_mmexcept(t)
    test_program(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_lexit(tester)
io.write("\n")
if tester:allPassed() then
    io.write("All tests successful\n")
else
    io.write("Tests ********** UNSUCCESSFUL **********\n")
    io.write("\n")
    io.write("**************************************************\n")
    io.write("* This test program is configured to execute all *\n")
    io.write("* tests, reporting success/failure for each. To  *\n")
    io.write("* make it exit after the first failing test, set *\n")
    io.write("* variable                                       *\n")
    io.write("*                                                *\n")
    io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
    io.write("*                                                *\n")
    io.write("* to true, near the start of the test program.   *\n")
    io.write("**************************************************\n")
end

-- Wait for user
io.write("\nPress ENTER to quit ")
io.read("*l")

