-- median.hs
-- Jim Samson
-- CS 331 Assignment 5
-- 25 April 2019

-- For CSF331 Spring 2019
-- Assignment 5 Part C

module Main where

import Data.List
import System.IO
import System.Exit

-- Main Loop
main = do
    putStrLn "Enter a set of integers, one on each line."
    putStrLn "This program will compute the median of the list"
    value <- median
    hFlush stdout

    if value == 9999999999
        then
            putStrLn ("You made an empty list")
        else do
            putStr ("The median is: ")
            print (value)
            
    hFlush stdout
    
    putStrLn "Continue? [y/n]:"
    startOver <- getLine
    if startOver == "y"
        then do
            main
        else do
            exitSuccess
        
-- Returns a list of integers typed by the user
getList = do	
    input <- getLine
    if input == "" 
        then 
            return []
        else do
            let n = read input :: Int
            next <- getList
            return (n:next)

-- Post Returns the median of the number
median = do
    n <- getList
    if length n == 0
        then
            return 9999999999
        else do 
            sortedList <- sortList (n)
            lengthList <- return (length sortedList)
            middle <- return (div lengthList 2)
            return (sortedList !! middle)


sortList list = do
    return (sort list)
    
