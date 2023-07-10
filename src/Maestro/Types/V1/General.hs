-- | Module to define types for /\"General\"/ endpoints defined at [docs.gomaestro.org](https://docs.gomaestro.org/docs/category/general).

module Maestro.Types.V1.General
  ( -- * Types for @/system-start@ endpoint
    SystemStart (..)
    -- * Types for @/era-history@ endpoint
  , EraSummaries (..)
  , EraSummary (..)
  , EraParameters (..)
  , EraBound (..)
    -- * Types for @/protocol-params@ endpoint
  , ProtocolVersion (..)
  , MemoryStepsWith (..)
  , CostModel (..)
  , CostModels (..)
  , MaestroRational (..)
  , textToMaestroRational
  , textFromMaestroRational
  , ProtocolParameters (..)
  , ProtocolParametersData (..)
    -- * Types for @/chain-tip@ endpoint
  , ChainTip (..)
  , ChainTipData (..)
  ) where

import           Control.Monad           (unless, when)
import           Data.Aeson              (FromJSON (parseJSON), toEncoding,
                                          toJSON, withText)
import           Data.Map.Strict         (Map)
import           Data.Ratio              (denominator, numerator, (%))
import           Data.Text               (Text)
import qualified Data.Text               as Txt
import qualified Data.Text.Read          as TxtRead
import           Data.Time               (LocalTime, NominalDiffTime)
import           Data.Word               (Word64)
import           Deriving.Aeson
import           Maestro.Types.V0.Common (BlockHash, EpochNo, EpochSize,
                                          LowerFirst, SlotNo)
import           Maestro.Types.V1.Common (LastUpdated (..))
import           Numeric.Natural         (Natural)

------------------------------------------------------------------
--  Types for @/system-start@ endpoint.
------------------------------------------------------------------

-- | Network start time since genesis.
data SystemStart = SystemStart
  { _systemStartData        :: !LocalTime
  -- ^ Network start time since genesis.
  , _systemStartLastUpdated :: !LastUpdated
  -- ^ See `LastUpdated`.
  }
  deriving stock (Eq, Ord, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_systemStart", CamelToSnake]] SystemStart

------------------------------------------------------------------
--  Types for @/era-history@ endpoint
------------------------------------------------------------------

-- | Network era summaries.
data EraSummaries = EraSummaries
  { _eraSummariesData        :: ![EraSummary]
  -- ^ Era summaries, see `EraSummary`.
  , _eraSummariesLastUpdated :: !LastUpdated
  -- ^ See `LastUpdated`.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_eraSummaries", LowerFirst]] EraSummaries

-- | Network era summary.
data EraSummary = EraSummary
  { _eraSummaryStart      :: !EraBound
  -- ^ Start of this era.
  , _eraSummaryEnd        :: !(Maybe EraBound)
  -- ^ End of this era.
  , _eraSummaryParameters :: !EraParameters
  -- ^ Parameters of this era.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_eraSummary", LowerFirst]] EraSummary

-- | Parameters for a network era which can vary between hardforks.
data EraParameters = EraParameters
  { _eraParametersEpochLength :: !EpochSize
  -- ^ Number of slots in an epoch.
  , _eraParametersSlotLength  :: !NominalDiffTime
  -- ^ How long a slot lasts.
  , _eraParametersSafeZone    :: !(Maybe Word64)
  -- ^ Number of slots from the tip of the ledger in which a hardfork will not happen.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_eraParameters", CamelToSnake]] EraParameters

-- | Bounds of an era.
data EraBound = EraBound
  { _eraBoundEpoch :: !EpochNo
  -- ^ Epoch number bounding this era.
  , _eraBoundSlot  :: !SlotNo
  -- ^ Absolute slot number bounding this era.
  , _eraBoundTime  :: !NominalDiffTime
  -- ^ Time relative to the start time of the network.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_eraBound", LowerFirst]] EraBound

------------------------------------------------------------------
--  Types for @/protocol-params@ endpoint.
------------------------------------------------------------------

-- | Current accepted protocol version. An increase in the major version indicates a hard fork, and the minor version a soft fork (meaning old software can validate but not produce new blocks).
data ProtocolVersion = ProtocolVersion
  { _protocolVersionMajor :: !Natural
  -- ^ Accepted protocol major version.
  , _protocolVersionMinor :: !Natural
  -- ^ Accepted protocol minor version.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_protocolVersion", LowerFirst]] ProtocolVersion

-- | Pair of memory & steps for the given type.
data MemoryStepsWith i = MemoryStepsWith
  { _memoryStepsWithMemory :: !i
  , _memoryStepsWithSteps  :: !i
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_memoryStepsWith", LowerFirst]] (MemoryStepsWith i)

-- | A cost model is a vector of coefficients that are used to compute the execution units required to execute a script. Its specifics depend on specific versions of the Plutus interpreter it is used with.
newtype CostModel = CostModel (Map Text Integer)
  deriving (Eq, Show)
  deriving newtype (ToJSON, FromJSON)

-- | Cost models (see `CostModel`) for script languages that use them.
data CostModels = CostModels
  { _costModelsPlutusV1 :: !CostModel
  , _costModelsPlutusV2 :: !CostModel
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_costModels", Rename "PlutusV1" "plutus:v1", Rename "PlutusV2" "plutus:v2"]] CostModels

-- | Maestro's represents rational numbers as string with numerator and denominator demarcated by \'\/\', example: @"1/3"@.
newtype MaestroRational = MaestroRational { unMaestroRational :: Rational }
  deriving stock Eq

instance Show MaestroRational where
  show (MaestroRational r) = show (numerator r) ++ '/' : show (denominator r)

-- | Get original `Text` from `MaestroRational`.
textFromMaestroRational :: MaestroRational -> Text
textFromMaestroRational = Txt.pack . show . unMaestroRational

-- | Parses given `Text` to `MaestroRational`.
textToMaestroRational :: Text -> Either String MaestroRational
textToMaestroRational ratTxt =
  case TxtRead.signed rationalReader ratTxt of
    Right (rat, remainingTxt) -> if Txt.null remainingTxt
      then pure $ MaestroRational rat
      else Left "Expected full string to be parsed"
    Left e -> Left e
  where
    rationalReader :: TxtRead.Reader Rational
    rationalReader ratTxt' = do
        (numr, remaining) <- TxtRead.decimal ratTxt'
        (nextChar, denmrTxt) <- maybe
            (Left "Unexpected end of string after parsing numerator")
            pure
            $ Txt.uncons remaining
        unless (nextChar == '/')
            . Left
            $ "Expected numerator to be immediately followed by '/', but it was followed by: " ++ show nextChar
        (denmr, finalRemaining) <- TxtRead.decimal denmrTxt
        when (denmr == 0)
            $ Left "Expected non-zero denominator"
        pure (numr % denmr, finalRemaining)

instance ToJSON MaestroRational where
  toEncoding = toEncoding . textFromMaestroRational
  toJSON = toJSON . textFromMaestroRational

instance FromJSON MaestroRational where
  parseJSON = withText "MaestroRational" $ \ratTxt -> either fail pure $ textToMaestroRational ratTxt

-- See `ProtocolParametersData`.
data ProtocolParameters = ProtocolParameters
  { _protocolParametersData        :: !ProtocolParametersData
  -- ^ See `ProtocolParametersData`.
  , _protocolParametersLastUpdated :: !LastUpdated
  -- ^ See `LastUpdated`.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_protocolParameters", CamelToSnake]] ProtocolParameters

-- | Protocol parameters for the latest epoch.
data ProtocolParametersData = ProtocolParametersData
  { _protocolParametersDataProtocolVersion                 :: !ProtocolVersion
  -- ^ See `ProtocolVersion`.
  , _protocolParametersDataMinFeeConstant                  :: !Natural
  -- ^ The linear factor for the minimum fee calculation for given epoch /AKA/ @min_fee_b@ and @tx_fee_fixed@.
  , _protocolParametersDataMinFeeCoefficient               :: !Natural
  -- ^ The constant factor for the minimum fee calculation /AKA/ @min_fee_a@ and @tx_fee_per_byte@.
  , _protocolParametersDataMaxBlockBodySize                :: !Natural
  -- ^ Maximum block body size.
  , _protocolParametersDataMaxBlockHeaderSize              :: !Natural
  -- ^ Maximum block header size.
  , _protocolParametersDataMaxTxSize                       :: !Natural
  -- ^ Maximum transaction size.
  , _protocolParametersDataStakeKeyDeposit                 :: !Natural
  -- 	The deposit required to register a stake address.
  , _protocolParametersDataPoolDeposit                     :: !Natural
  -- ^ The amount of a pool registration deposit in lovelaces /AKA/ @stake_pool_deposit@.
  , _protocolParametersDataPoolRetirementEpochBound        :: !EpochNo
  -- ^ The maximum number of epochs into the future that stake pools are permitted to schedule a retirement /AKA/ @pool_retire_max_epoch@, @e_max@.
  , _protocolParametersDataDesiredNumberOfPools            :: !Natural
  -- The equilibrium target number of stake pools. This is the \"k\" incentives parameter from the design document, /AKA/ @n_opt@, @stake_pool_target@.
  , _protocolParametersDataPoolInfluence                   :: !MaestroRational
  -- The influence of the pledge in stake pool rewards. This is the \"a_0\" incentives parameter from the design document.
  , _protocolParametersDataMonetaryExpansion               :: !MaestroRational
  -- ^ The monetary expansion rate. This determines the fraction of the reserves that are added to the fee pot each epoch. This is the \"rho\" incentives parameter from the design document.
  , _protocolParametersDataTreasuryExpansion               :: !MaestroRational
  -- ^ The fraction of the fee pot each epoch that goes to the treasury. This is the \"tau\" incentives parameter from the design document, /AKA/ @treasury_cut@.
  , _protocolParametersDataMinPoolCost                     :: !Natural
  -- ^ The minimum value that stake pools are permitted to declare for their cost parameter.
  , _protocolParametersDataPrices                          :: !(MemoryStepsWith MaestroRational)
  -- ^ The price per unit memory & price per reduction step corresponding to abstract notions of the relative memory usage and script execution steps respectively.
  , _protocolParametersDataMaxExecutionUnitsPerTransaction :: !(MemoryStepsWith Natural)
  -- ^ The maximum number of execution memory & steps allowed to be used in a single transaction.
  , _protocolParametersDataMaxExecutionUnitsPerBlock       :: !(MemoryStepsWith Natural)
  -- ^ The maximum number of execution memory & steps allowed to be used in a single block.
  , _protocolParametersDataMaxValueSize                    :: !Natural
  -- ^ Maximum size of the /value/ part of an output in a serialized transaction.
  , _protocolParametersDataCollateralPercentage            :: !Natural
  -- ^ The percentage of the transactions fee which must be provided as collateral when including non-native scripts.
  , _protocolParametersDataMaxCollateralInputs             :: !Natural
  -- ^ The maximum number of collateral inputs allowed in a transaction.
  , _protocolParametersDataCoinsPerUtxoByte                :: !Natural
  -- ^ The cost per UTxO size. Cost per UTxO /word/ for Alozno. Cost per UTxO /byte/ for Babbage and later.
  , _protocolParametersDataCostModels                      :: !CostModels
  -- ^ See `CostModels`.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_protocolParametersData", CamelToSnake]] ProtocolParametersData

------------------------------------------------------------------
--  Types for @/chain-tip@ endpoint.
------------------------------------------------------------------

-- | Details about the most recently adopted block.
data ChainTipData = ChainTipData
  { _chainTipDataBlockHash :: !BlockHash
  -- ^ Hash of this most recent block.
  , _chainTipDataSlot      :: !SlotNo
  -- ^ Slot number for this most recent block.
  , _chainTipDataHeight    :: !Word64
  -- ^ Block number (height) of this most recent block.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_chainTipData", CamelToSnake]] ChainTipData


-- | See `ChainTipData`.
data ChainTip = ChainTip
  { _chainTipData        :: !ChainTipData
  -- ^ See `ChainTipData`.
  , _chainTipLastUpdated :: !LastUpdated
  -- ^ See `LastUpdated`.
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[StripPrefix "_chainTip", CamelToSnake]] ChainTip
