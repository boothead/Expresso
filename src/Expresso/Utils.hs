{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
module Expresso.Utils(
  Fix(..),
  K(..),
  (:*:)(..),
  (:+:)(..),
  cata,
  cataM,
  para,
  ana,
  (&&&),
  first,
  second,
  showError,
  View(..)
)
where

import Control.Monad

newtype Fix f = Fix { unFix :: f (Fix f) }

data K a b = K { unK :: a }
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

data (f :*: g) a = (:*:) { left :: f a, right :: g a }
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

data (f :+: g) a = InL (f a) | InR (g a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

cata :: Functor f => (f a -> a) -> Fix f -> a
cata phi = phi . fmap (cata phi) . unFix


cataM :: (Monad m, Traversable f) =>
         (f a -> m a) -> Fix f -> m a
cataM algM = algM <=< (mapM (cataM algM) . unFix)

para :: Functor f => (f (b, Fix f) -> b) -> Fix f -> b
para phi = phi . fmap (para phi &&& id) . unFix

ana :: Functor f => (a -> f a) -> a -> Fix f
ana coalg = Fix . fmap (ana coalg) . coalg

-- Equivalent to specialized version from Arrow
(&&&) :: (a -> b) -> (a -> c) -> (a -> (b,c))
f &&& g = \a -> (f a, g a)

-- Equivalent to specialized version from Arrow
first :: (a -> b) -> (a,c) -> (b,c)
first f (a,c) = (f a, c)

-- Equivalent to specialized version from Arrow
second :: (b -> c) -> (a,b) -> (a,c)
second f (a,b) = (a, f b)

instance (Functor f, Show (f (Fix f))) => Show (Fix f) where
    showsPrec d (Fix f) = showsPrec d f

instance (Functor f, Eq (f (Fix f))) => Eq (Fix f) where
    fa == fb = unFix fa == unFix fb

instance (Functor f, Ord (f (Fix f))) => Ord (Fix f) where
    compare fa fb = compare (unFix fa) (unFix fb)

class View f a where
  proj :: a -> f a
  inj  :: f a -> a

showError :: Show a => Either a b -> Either String b
showError = either (Left . show) Right