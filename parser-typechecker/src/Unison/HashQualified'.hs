{-# LANGUAGE OverloadedStrings #-}

module Unison.HashQualified' where

import           Data.Maybe                     ( fromJust )
import           Data.Text                      ( Text )
import qualified Data.Text                     as Text
import           Data.String                    ( IsString
                                                , fromString
                                                )
import           Prelude                 hiding ( take )
import           Unison.Name                    ( Name )
import qualified Unison.Name                   as Name
import           Unison.Reference               ( Reference )
import qualified Unison.Reference              as Reference
import           Unison.Referent                ( Referent )
import qualified Unison.Referent               as Referent
import           Unison.ShortHash               ( ShortHash )
import qualified Unison.ShortHash              as SH
import qualified Unison.HashQualified          as HQ

data HashQualified' n = NameOnly n | HashQualified n ShortHash
  deriving (Eq, Ord)

type HashQualified = HashQualified' Name

toHQ :: HashQualified' n -> HQ.HashQualified' n
toHQ = \case
  NameOnly n -> HQ.NameOnly n
  HashQualified n sh -> HQ.HashQualified n sh

toName :: HashQualified' n -> n
toName = \case
  NameOnly name        ->  name
  HashQualified name _ ->  name

take :: Int -> HashQualified' n -> HashQualified' n
take i = \case
  n@(NameOnly _)    -> n
  HashQualified n s -> if i == 0 then NameOnly n else HashQualified n (SH.take i s)

toNameOnly :: HashQualified' n -> HashQualified' n
toNameOnly = fromName . toName

toHash :: HashQualified -> Maybe ShortHash
toHash = \case
  NameOnly _         -> Nothing
  HashQualified _ sh -> Just sh

toString :: Show n => HashQualified' n -> String
toString = Text.unpack . toText

-- Parses possibly-hash-qualified into structured type.
fromText :: Text -> Maybe HashQualified
fromText t = case Text.breakOn "#" t of
  (name, ""  ) ->
    Just $ NameOnly (Name.unsafeFromText name) -- safe bc breakOn #
  (name, hash) ->
    HashQualified (Name.unsafeFromText name) <$> SH.fromText hash

unsafeFromText :: Text -> HashQualified
unsafeFromText = fromJust . fromText

fromString :: String -> Maybe HashQualified
fromString = fromText . Text.pack

toText :: Show n => HashQualified' n -> Text
toText = \case
  NameOnly name           -> Text.pack (show name)
  HashQualified name hash -> Text.pack (show name) <> SH.toText hash

-- Returns the full referent in the hash.  Use HQ.take to just get a prefix
fromNamedReferent :: n -> Referent -> HashQualified' n
fromNamedReferent n r = HashQualified n (Referent.toShortHash r)

-- Returns the full reference in the hash.  Use HQ.take to just get a prefix
fromNamedReference :: n -> Reference -> HashQualified' n
fromNamedReference n r = HashQualified n (Reference.toShortHash r)

fromName :: n -> HashQualified' n
fromName = NameOnly

matchesNamedReferent :: Name -> Referent -> HashQualified -> Bool
matchesNamedReferent n r = \case
  NameOnly n' -> n' == n
  HashQualified n' sh -> n' == n && sh `SH.isPrefixOf` Referent.toShortHash r

matchesNamedReference :: Name -> Reference -> HashQualified -> Bool
matchesNamedReference n r = \case
  NameOnly n' -> n' == n
  HashQualified n' sh -> n' == n && sh `SH.isPrefixOf` Reference.toShortHash r

-- Use `requalify hq . Referent.Ref` if you want to pass in a `Reference`.
requalify :: HashQualified -> Referent -> HashQualified
requalify hq r = case hq of
  NameOnly n        -> fromNamedReferent n r
  HashQualified n _ -> fromNamedReferent n r


instance IsString HashQualified where
  fromString = unsafeFromText . Text.pack


instance Show n => Show (HashQualified' n) where
  show = Text.unpack . toText
