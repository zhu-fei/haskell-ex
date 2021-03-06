{-# LANGUAGE RecordWildCards #-}
-- # Reposts

-- Question:
-- seven prizes will be given to seven randomly chosen people among those who
-- have reposted a certain post. There are already ~1,000,000 reposts.
-- My sister wonders: what's the probability of her winning at least one prize
-- (out of those seven) if she reposts the post 10 times
-- (from different accounts)? What about 100 times? 1000 times?

-- Notes:
-- Calculate the answer by running a simulation some number of times
-- (for instance, 10000 times). You can use System.Random or some other
-- random library (e.g. Data.Random).


module Main where

import qualified Data.List as List
import qualified System.Random as Random
import qualified Text.Printf as Print
import qualified Control.Monad as Monad



--  * Pick values for three variables:
--    * a total repost count A
--    * count of winners drawn B
--    * Bob's count of reposts C
--  * Imagine that reposts can be identified by their index in the repost count
--  * Now select winners by randomly generating B indexes in range of A
--  * Now Check how many winners are between 1-C. Yes this assumes that Bob
--    has a contiguous serious of reposts beginning at the head of list A.
--    However! This unlikely detail is inconsequential for the purposes of
--    calculating the probability of Bob being amongst the winners.
--
--    TODO Parallel Approach (credit for idea is @neongreen)
--
--      Observation 1
--      If you have some winners and you want to check whether any
--      of them won, you just have to check whether the lowest one won.
--
--      Observation 2
--      If you know the lowest winner, you can check whether it's less than
--      10/100/1000 and get 3 booleans (would be simpler to implement as 3 Ints)
--
--      So...
--      Then you just sum up 10000 of those triples and get 3 answers
--      simultaneously!



type Winners = [Int]
data DrawOutcome = Lost | Won deriving (Show,Eq)



data Experiment = Experiment {
  prizeCount :: Int,
  repostCount :: Int,
  myReposts :: Int
} deriving (Show)



-- Report on several experiments varying by how many times I repost.

main :: IO ()
main = do
  printChanceIfmyReposts 10
  printChanceIfmyReposts 100
  printChanceIfmyReposts 1000
  where
  printChanceIfmyReposts n = do
    let e = Experiment { myReposts = n, repostCount = 1000000, prizeCount = 7 }
    Print.printf
      "Given %s\nthe probability of winning is %F%%.\n\n"
      (show e)
      (myChanceIf e)



-- Run an experiment many times and then calculate how likely I am to win.

myChanceIf :: Experiment -> Double
myChanceIf experiment = probability
  where

  probability = realToFrac winCount / realToFrac iterations * 100
  winCount = length . filter (== Won) . runExperimentTimes experiment $ iterations
  iterations = 100000

  runExperimentTimes :: Experiment -> Int -> [DrawOutcome]
  runExperimentTimes experiment numOfRuns =
    List.unfoldr go (1, Random.split (Random.mkStdGen 1))
    where
    go (runNum, (g1,g2))
      | runNum > numOfRuns = Nothing
      | otherwise = Just (
          runExperiment g1 experiment,
          (runNum + 1, Random.split g2)
        )



-- Run an experiment showing if I win or lose.

runExperiment :: Random.RandomGen g => g -> Experiment -> DrawOutcome
runExperiment generator Experiment{..} =
  boolToOutcome .
  any (<= myReposts) .
  take prizeCount .
  List.nub . -- Avoid duplicates. May arise since random...
  Random.randomRs (1, repostCount)
  $ generator



boolToOutcome :: Bool -> DrawOutcome
boolToOutcome True = Won
boolToOutcome False = Lost

countUnique :: Eq a => [a] -> Int
countUnique = length . List.nub
