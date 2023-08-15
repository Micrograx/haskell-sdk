module Maestro.API.V1.Transactions where

import           Maestro.Client.V1.Core.Pagination
import           Maestro.Types.V1
import           Servant.API
import           Servant.API.Generic

data TransactionsAPI route = TransactionsAPI
  { _txOutputs
      :: route
      :- "transactions"
      :> "outputs"
      :> QueryParam "resolve_datums" Bool
      :> QueryParam "with_cbor" Bool
      :> Pagination
      :> ReqBody '[JSON] [OutputReference]
      :> Post '[JSON] PaginatedUtxo
  , _txDetailsByHash
      :: route
      :- "transactions"
      :> Capture "tx_hash" (HashStringOf Tx)
      :> Get '[JSON] TimestampedTxDetails
  }
  deriving (Generic)
