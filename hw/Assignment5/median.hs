--Samuel Grenon
--CS 331
--26 Mar 2018
--median.hs This program takes input from a user
--and returns a median of the numbers

import Data.List
import System.IO


-- main loop
main = do
    putStrLn "Enter a list of numbers use a blank line to exit"
    value <- median
    hFlush stdout
    if value == 9999999999
        then
            putStrLn ("You made an empty list")
        else do
            putStr ("The median is ")
            print (value)
            
    hFlush stdout
    
    putStrLn "Do you want to play again [y/n]"
    startOver <- getLine
    if startOver == "y"
        then do
            main
        else do
            putStrLn "Bye"
        
-- Pre None
-- Post Returns a list of Integers typed by the user
getList = do	
    input <- getLine
    if input == "" 
        then 
            return []
        else do
            let n = read input :: Int
            next <- getList
            return (n:next)

--Pre None
--Post Returns the median of the number
median = do
    n <- getList
    if length n == 0
        then
            return 9999999999
            --error ("Empty List") -- Exit with error message
        else do 
            sortedList <- sortList (n)
            lengthList <- return (length sortedList)
            midList <- return (div lengthList 2)
            return (sortedList !! midList)


sortList list = do
    return (sort list)
    
