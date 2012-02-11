--------------------------------------------------------------------
-- |
-- Module    : Text.Regex.Applicative.Reference
-- Copyright : (c) Roman Cheplyaka
-- License   : MIT
--
-- Maintainer: Roman Cheplyaka <roma@ro-che.info>
-- Stability : experimental
--
-- Reference implementation (using backtracking)
--------------------------------------------------------------------

module Text.Regex.Applicative.Reference (reference) where
import Prelude hiding (getChar)
import Text.Regex.Applicative.Types
import Control.Applicative
import Control.Monad


-- A simple parsing monad
newtype P s a = P { unP :: [s] -> [(a, [s])] }

instance Monad (P s) where
    return x = P $ \s -> [(x, s)]
    (P a) >>= k = P $ \s ->
        a s >>= \(x,s) -> unP (k x) s

instance Functor (P s) where
    fmap = liftM

instance Applicative (P s) where
    (<*>) = ap
    pure = return

instance Alternative (P s) where
    empty = P $ const []
    P a1 <|> P a2 = P $ \s ->
        a1 s ++ a2 s

getChar :: P s s
getChar = P $ \s ->
    case s of
        [] -> []
        c:cs -> [(c,cs)]

re2monad :: RE s a -> P s a
re2monad r =
    case r of
instance Regexp P where
    reEps -> return $ error "eps"
    reSymbol _ p -> do
        c <- getChar
        if p c then return c else empty
    reAlt a1 a2 -> re2monad a1 <|> re2monad a2
    reApp a1 a2 -> re2monad a1 <*> re2monad a2
    reFmap f a -> fmap f $ re2monad a
    reRep g f b a -> rep b
        where
        am = re2monad a
        rep b = combine (do a <- am; rep $ f b a) (return b)
        combine a b = case g of Greedy -> a <|> b; NonGreedy -> b <|> a
    reVoid a -> re2monad a >> return ()

runP :: P s a -> [s] -> Maybe a
runP m s = case filter (null . snd) $ unP m s of
    (r, _) : _ -> Just r
    _ -> Nothing

-- | 'reference' @r@ @s@ should give the same results as @s@ '=~' @r@.
--
-- However, this is not very efficient implementation and is supposed to be
-- used for testing only.
reference :: RE s a -> [s] -> Maybe a
reference r s = runP (re2monad r) s
