-- PA5.hs  
-- Samuel J Grenon
-- 26 Mar 2018
--
-- For CS F331 / CSCE A331 Spring 2018
-- Solutions to Assignment 5 Exercise B

module PA5 where
import Data.List

--collatz
--Takes a number num and uses the collatz process
collatz n 
  | n == 0 = 0
  | mod n 2 == 0 = div n 2
  | otherwise = 3*n+1

--collatzSequence
--Uses the collatz function until 1
collatzSequence n
  | n == 1 = 0
  | collatz n == 1 = 1
  | otherwise = 1 + collatzSequence (collatz n) 



-- collatzCounts
collatzCounts :: [Integer]
collatzCounts = map collatzSequence[1..]


-- findList
-- returns the number of continguous sublists of two
-- lists
findList :: Eq a => [a] -> [a] -> Maybe Int
findList list1 list2 = findIndex (isPrefixOf list1) (tails list2)


-- operator ##
-- returns the number of indicies at which the two lists contain
-- the same value
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
-- It returns a tuple of two numbers: the sum of the even-index items 
-- in the given list, and the sum of the odd-index items in the given 
-- list. Indices are zero-based.

sumEvenOdd list = tuple where
    tupleComp = component list
    even = foldr (+) 0 (getFirst tupleComp)
    odd = foldr (+) 0 (getSecond tupleComp)
    tuple = (even, odd)

