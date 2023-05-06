module Maestro.Types.Epoch ( EpochInfo ) where

import           Data.Time.Clock.POSIX (POSIXTime)
import           Deriving.Aeson
import           Maestro.Types.Common

data EpochInfo = EpochInfo
  { _maeEphEpochNo   :: !EpochNo
  , _maeEphFees      :: !Integer
  , _maeEphTxCount   :: !Integer
  , _maeEphBlkCount  :: !Integer
  , _maeEphStartTime :: !POSIXTime
  , _maeEphEndTime   :: !POSIXTime
  }
  deriving stock (Show, Eq, Generic)
  deriving (FromJSON, ToJSON)
  via CustomJSON '[FieldLabelModifier '[StripPrefix "_maeEph", CamelToSnake]] EpochInfo
