mergesort :: Ord a => [a] -> [a]
mergesort []  = []
mergesort [x] = [x]
mergesort xs  = merge (mergesort a) (mergesort b)
  where (a, b) = divide xs

merge :: Ord a => [a] -> [a] -> [a]
merge [] ys = ys
merge xs [] = xs
merge (x:xs) (y:ys)
  | x <= y    = x : merge xs (y:ys)
  | otherwise = y : merge (x:xs) ys

divide :: [a] -> ([a], [a])
divide = go [] []
  where
    go as bs []     = (as, bs)
    go as bs (x:xs) = go bs (x:as) xs
