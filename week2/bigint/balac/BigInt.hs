module BigInt ( BigInt, bigToInteger ) where

import Data.List

data BigInt = BI Bool [Int]

bZero = BI True [0]
bOne  = BI True [1]

instance Show BigInt where
    show (BI p cs) = ( if p then "" else "-" ) ++ reverse ( concatMap show cs )

kBase :: Int
--kBase = floor ( sqrt ( fromIntegral ( maxBound :: Int ) ) ) :: Int 
kBase = 10

iBase :: Integer
iBase = fromIntegral kBase

bigToInteger :: BigInt -> Integer
bigToInteger (BI pos xs) = sign * foldr (\term sum -> sum * iBase + fromIntegral term ) 0 xs
    where
        sign = if pos then 1 else -1

toBase :: Integer -> Integer -> [Int]
toBase x base
    | x < base = [ fromIntegral x ]
    | otherwise = fromIntegral rem : toBase divid base
    where
        ( divid, rem ) = divMod x base

coeffSum :: [Int] -> [Int] -> [Int]
coeffSum [] ys = ys
coeffSum xs [] = xs
coeffSum (x:xs) (y:ys)
    | termSum < kBase = termSum : coeffSum xs ys
    | otherwise = mod termSum kBase : coeffSum ( coeffSum xs [1] ) ys
    where
        termSum = x + y

coeffDiff :: [Int] -> [Int] -> [Int]
coeffDiff [] _ = []
coeffDiff xs [] = xs
coeffDiff (x:xs) (y:ys)
    | termDiff >= 0 = termDiff : coeffDiff xs ys
    | otherwise = termDiff + kBase : coeffDiff ( coeffDiff xs [1] ) ys
    where
        termDiff = x - y

coeffShift :: Int -> [Int] -> [Int]
coeffShift _ [] = []
coeffShift n cs = replicate n 0 ++ cs

coeffMultScalar :: Int -> [Int] -> [Int]
coeffMultScalar _ [] = []
coeffMultScalar 0 _  = []
coeffMultScalar 1 cs = cs
coeffMultScalar n (x:xs)
    | termProd < kBase = termProd : coeffMultScalar n xs
    | otherwise = rem : coeffSum ( coeffMultScalar n xs ) [ divid ]
    where
        termProd = n * x
        ( divid, rem ) = divMod termProd kBase


coeffMultiply :: [Int] -> [Int] -> [Int]
coeffMultiply xs ys = foldl' coeffSum [0::Int] shiftedScalarProducts
    where
        scalarProducts = map ( `coeffMultScalar` xs ) ys
        shiftedScalarProducts = map (\( coeff, shift ) -> coeffShift shift coeff ) $ zip scalarProducts [0..]

dropZeros :: [Int] -> [Int] 
dropZeros = reverse . dropWhile (== 0) . reverse

unsignedSub :: [Int] -> [Int] -> [Int]
unsignedSub xs ys = 
    case coeffsCompare xs ys of
        EQ -> [0]
        GT -> dropZeros $ coeffDiff xs ys
        LT -> dropZeros $ coeffDiff ys xs

instance Eq BigInt where
    (==) (BI _ [0]) (BI _ [0]) = True
    (==) (BI posx xs) (BI posy ys) = ( posx == posy ) && xs == ys

revCoeffsCompare :: [Int] -> [Int] -> Ordering
revCoeffsCompare [] [] = EQ
revCoeffsCompare (x:xs) (y:ys)
    | length xs < length ys = LT
    | length ys < length xs = GT
    | x < y = LT
    | y < x = GT
    | otherwise = revCoeffsCompare xs ys

coeffsCompare xs ys = revCoeffsCompare ( reverse xs ) ( reverse ys )

instance Ord BigInt where
    compare (BI _ [0]) (BI _ [0]) = EQ
    compare x@(BI posx xs) y@(BI posy ys) = case (posx, posy) of
                                                (False,True) -> LT
                                                (True,False) -> GT
                                                (True,True)  -> coeffsCompare xs ys
                                                (False,False)-> coeffsCompare ys xs

instance Num BigInt where
    (+) x@(BI posx xs) y@(BI posy ys) = case (posx, posy) of
                                            (True, True)    -> BI True ( coeffSum xs ys )
                                            (True, False)   -> BI sign ( unsignedSub xs ys )
                                            (False, True)   -> BI (not sign) ( unsignedSub xs ys )
                                            (False, False)  -> BI False ( coeffSum xs ys )
                                            where
                                                sign = abs x >= abs y
    (*) (BI _ [0]) (BI _ _) = bZero
    (*) (BI _ _) (BI _ [0]) = bZero
    (*) (BI posx xs) (BI posy ys) = if posx == posy
                                        then BI True ( coeffMultiply xs ys )
                                        else BI False ( coeffMultiply xs ys )
    abs ( BI _ coeffs ) = BI True coeffs
    signum ( BI _ [0] )  = BI True [0]
    signum ( BI pos _  ) = BI pos [1]
    fromInteger x = BI pos coeffs
        where
            pos     = x >= 0
            coeffs  = toBase ( abs x ) ( fromIntegral kBase )
    negate (BI p cs) = BI ( not p ) cs  
