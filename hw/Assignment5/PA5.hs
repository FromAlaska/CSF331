-- PA5.hs
-- Jim Samson
-- 
-- For CS F331 / CSCE A331 Spring 2019
-- Solutions to Assignment 5 Exercise B

module PA5 where
import Data.List

-- Collatz Function
-- collatz(n) = 3*n + 1 if n is odd
--              n/2 	if n is even
collatz n
	| n == 0 = 0
	| n `mod` 2 /= 0 = 3*n+1
	| otherwise = n `div` 2


-- Collatz Sequence Function
-- collatzSequence
-- Uses the collatz function until 1
collatzSequence n
  | n == 1 = 0
  | collatz n == 1 = 1
  | otherwise = 1 + collatzSequence (collatz n) 


-- Collatz Counts Function
-- collatzCounts
-- Determines the number of times it takes to get n down to 1 using the Collatz function.
-- If collatz(n) is not 1, it calls collatzCount again on collatz(n) 
collatzCounts :: [Integer]
collatzCounts = map collatzSequence[1..]


-- Find List Function
-- findList
-- returns the number of continguous sublists of two lists
findList :: Eq a => [a] -> [a] -> Maybe Int
findList list1 list2 = findIndex (isPrefixOf list1) (tails list2)


-- operator ##
-- returns the number of indicies at which the two lists containthe same value
(##) :: Eq a => [a] -> [a] -> Int
list1 ## list2 = length $ filter (\(x,y) -> x == y) $ zip list1 list2
list2Value ( _, list2) = list2

-- filterAB
-- It returns a list of all items in the second list for 
-- which the corresponding item in the first list
-- makes the boolean function true.
filterAB :: (a -> Bool) -> [a] -> [b] -> [b]


filterAB test list1 list2 = list where
  newList = (filter (test.fst) $ zip list1 list2)
  list = list2Value(unzip newList)

getFirst (first,_) = first
getSecond (_,second) = second


component [] = ([],[])
component [x] = ([x], [])
component (x:y:xs) = (x:xp, y:yp) where (xp, yp) = component xs

-- sumEvenOdd
-- This takes a list of numbers. 
-- It returns a tuple of two numbers: the sum of the even-index items in the given list, 
-- and the sum of the odd-index items in the given list. Indices are zero-based. 

sumEvenOdd list = tuple where
    tupleNumbers = component list
    even = foldr (+) 0 (getFirst tupleNumbers)
    odd = foldr (+) 0 (getSecond tupleNumbers)
    tuple = (even, odd)
