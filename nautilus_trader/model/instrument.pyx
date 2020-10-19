# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2020 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------

from cpython.datetime cimport datetime

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.fraction cimport Fraction
from nautilus_trader.model.c_enums.asset_type cimport AssetType
from nautilus_trader.model.c_enums.liquidity_side cimport LiquiditySide
from nautilus_trader.model.c_enums.liquidity_side cimport liquidity_side_to_string
from nautilus_trader.model.c_enums.position_side cimport PositionSide
from nautilus_trader.model.c_enums.position_side cimport position_side_to_string
from nautilus_trader.model.currency cimport Currency
from nautilus_trader.model.identifiers cimport Symbol
from nautilus_trader.model.objects cimport Decimal
from nautilus_trader.model.objects cimport Quantity


cdef class Instrument:
    """
    Represents a tradeable financial market instrument.
    """

    def __init__(
            self,
            Symbol symbol not None,
            AssetClass asset_class,
            AssetType asset_type,
            Currency base_currency not None,
            Currency quote_currency not None,
            Currency settlement_currency not None,
            int price_precision,
            int size_precision,
            Decimal multiplier not None,
            Decimal tick_size not None,
            Decimal leverage not None,
            Quantity lot_size not None,
            Quantity max_quantity,  # Can be None
            Quantity min_quantity,  # Can be None
            Money max_notional,     # Can be None
            Money min_notional,     # Can be None
            Price max_price,        # Can be None
            Price min_price,        # Can be None
            Decimal margin_initial not None,
            Decimal margin_maintenance not None,
            Decimal maker_fee not None,
            Decimal taker_fee not None,
            Decimal settlement_fee not None,
            Decimal funding_rate_long not None,
            Decimal funding_rate_short not None,
            datetime timestamp not None,
            dict info=None,
    ):
        """
        Initialize a new instance of the Instrument class.

        Parameters
        ----------
        symbol : Symbol
            The symbol.
        asset_type : AssetClass
            The asset class.
        asset_type : AssetType
            The asset type.
        base_currency : Currency
            The base currency.
        quote_currency : Currency
            The quote currency.
        settlement_currency : Currency
            The settlement currency.
        price_precision : int
            The price decimal precision.
        size_precision : int
            The trading size decimal precision.
        tick_size : Decimal
            The tick size.
        leverage : Decimal
            The current leverage for the instrument.
        multiplier : Decimal
            The contract value multiplier.
        lot_size : Quantity
            The rounded lot unit size.
        max_quantity : Quantity
            The maximum possible order quantity.
        min_quantity : Quantity
            The minimum possible order quantity.
        max_notional : Money
            The maximum possible order notional value.
        min_notional : Money
            The minimum possible order notional value.
        max_price : Price
            The maximum possible printed price.
        min_price : Price
            The minimum possible printed price.
        margin_initial : Decimal
            The initial margin requirement in percentage of order value.
        margin_maintenance : Decimal
            The maintenance margin in percentage of position value.
        maker_fee : Decimal
            The fee rate for liquidity makers as a percentage of order value.
        taker_fee : Decimal
            The fee rate for liquidity takers as a percentage of order value.
        settlement_fee : Decimal
            The fee rate for settlements as a percentage of order value.
        funding_rate_long : Decimal
            The funding rate for long positions.
        funding_rate_short : Decimal
            The funding rate for short positions.
        timestamp : datetime
            The timestamp the instrument was created/updated at.
        info : dict, optional
            For more detailed and exchange specific instrument information.

        Raises
        ------
        ValueError
            If asset type is UNDEFINED.
        ValueError
            If price precision is negative (< 0).
        ValueError
            If size precision is negative (< 0).
        ValueError
            If tick size is not positive (> 0).
        ValueError
            If lot size is not positive (> 0).
        ValueError
            If leverage is not positive (> 0).

        """
        if info is None:
            info = {}
        Condition.not_equal(asset_type, AssetType.UNDEFINED, 'asset_type', 'UNDEFINED')
        Condition.not_negative_int(price_precision, 'price_precision')
        Condition.not_negative_int(size_precision, 'volume_precision')
        Condition.positive(tick_size, "tick_size")
        Condition.positive(lot_size, "lot_size")
        Condition.positive(leverage, "leverage")

        self.symbol = symbol
        self.asset_class = asset_class
        self.asset_type = asset_type
        self.base_currency = base_currency
        self.quote_currency = quote_currency
        self.settlement_currency = settlement_currency
        self.is_inverse = info.get("is_inverse", False)
        self.is_quanto = info.get("is_quanto", False)
        self.price_precision = price_precision
        self.size_precision = size_precision
        self.cost_precision = self.settlement_currency.precision
        self.tick_size = tick_size
        self.multiplier = multiplier
        self.leverage = leverage
        self.lot_size = lot_size
        self.max_quantity = max_quantity
        self.min_quantity = min_quantity
        self.max_notional = max_notional
        self.min_notional = min_notional
        self.max_price = max_price
        self.min_price = min_price
        self.margin_initial = margin_initial
        self.margin_maintenance = margin_maintenance
        self.maker_fee = maker_fee
        self.taker_fee = taker_fee
        self.settlement_fee = settlement_fee
        self.funding_rate_long = funding_rate_long
        self.funding_rate_short = funding_rate_short
        self.timestamp = timestamp

    def __eq__(self, Instrument other) -> bool:
        """
        Return a value indicating whether this object is equal to (==) the given object.

        Parameters
        ----------
        other : object
            The other object to equate.

        Returns
        -------
        bool

        """
        return self.symbol == other.symbol

    def __ne__(self, Instrument other) -> bool:
        """
        Return a value indicating whether this object is not equal to (!=) the given object.

        Parameters
        ----------
        other : object
            The other object to equate.

        Returns
        -------
        bool

        """
        return not self == other

    def __hash__(self) -> int:
        """
        Return the hash code of this object.

        Returns
        -------
        int

        """
        return hash(self.symbol.value)

    def __str__(self) -> str:
        """
        Return the string representation of this object.

        Returns
        -------
        str

        """
        return f"{self.__class__.__name__}({self.symbol.value})"

    def __repr__(self) -> str:
        """
        Return the string representation of this object which includes the objects
        location in memory.

        Returns
        -------
        str

        """
        return f"<{str(self)} object at {id(self)}>"

    cpdef Money calculate_pnl(
        self,
        PositionSide side,
        Fraction open_price,
        Fraction close_price,
        Quantity quantity,
    ):
        """
        Calculate the PNL from the given parameters.

        Parameters
        ----------
        side : PositionSide
            The side of the trade.
        open_price : Fraction
            The average open price of the trade.
        close_price : Fraction
            The average close price of the trade.
        quantity : Quantity
            The quantity

        Returns
        -------
        Money
            In the base currency for the instrument.

        """
        cdef Fraction return_percentage = self._calculate_return(
            side,
            open_price,
            close_price,
        )

        cdef Fraction pnl = return_percentage * quantity * self.multiplier

        if self.is_inverse:
            pnl *= (1 / close_price)

        return Money(pnl, self.base_currency)

    cpdef Money calculate_pnl_for_settlement(
            self,
            PositionSide side,
            Fraction open_price,
            Fraction close_price,
            Quantity quantity,
            double xrate=1.,
    ):
        """
        Calculate the PNL from the given parameters.

        Parameters
        ----------
        side : PositionSide
            The side of the trade.
        open_price : Fraction
            The average open price of the trade.
        close_price : Fraction
            The average close price of the trade.
        quantity : Quantity
            The quantity
        xrate : double
            The exchange rate between the base currency and the settlement
            currency.

        Returns
        -------
        Money
            In the settlement currency for the instrument.

        """
        cdef Money pnl = self.calculate_pnl(
            side,
            open_price,
            close_price,
            quantity,
        )

        return Money(pnl * xrate, self.settlement_currency)

    cpdef Money calculate_commission(
        self,
        Quantity quantity,
        Price avg_price,
        LiquiditySide liquidity_side,
    ):
        """
        Calculate the commission generated by transacting the given quantity
        with the given liquidity side.

        Parameters
        ----------
        quantity : Quantity
            The quantity for the transaction.
        avg_price : Price
            The average price transaction (only applicable for inverse
            instruments, else ignored).
        liquidity_side : LiquiditySide
            The liquidity side for the transaction.

        Returns
        -------
        Money
            In the base currency for the instrument.

        """
        cdef Fraction notional = quantity * self.multiplier

        if self.is_inverse:
            notional *= (1 / avg_price)

        if liquidity_side == LiquiditySide.MAKER:
            commission = notional * self.maker_fee
        elif liquidity_side == LiquiditySide.TAKER:
            commission = notional * self.taker_fee
        else:
            raise ValueError(f"Cannot calculate commission "
                             f"(liquidity side was {liquidity_side_to_string(liquidity_side)}).")

        commission += commission * self.settlement_fee

        return Money(commission, self.base_currency)

    cpdef Money calculate_commission_for_settlement(
            self,
            Quantity quantity,
            Price avg_price,
            LiquiditySide liquidity_side,
            double xrate=1.,
    ):
        """
        Calculate the commission generated by transacting the given quantity
        with the given liquidity side.

        Parameters
        ----------
        quantity : Quantity
            The quantity for the transaction.
        avg_price : Price
            The average price transaction (only applicable for inverse
            instruments, else ignored).
        liquidity_side : LiquiditySide
            The liquidity side for the transaction.
        xrate : double
            The exchange rate between the base currency and the settlement
            currency (only applicable for quanto instruments, else ignored).

        Returns
        -------
        Money
            In the base currency for the instrument.

        """
        cdef Money commission = self.calculate_commission(
            quantity,
            avg_price,
            liquidity_side,
        )

        return Money(commission * xrate, self.settlement_currency)

    cdef inline Fraction _calculate_return(
        self,
        PositionSide side,
        Fraction open_price,
        Fraction close_price,
    ):
        if side == PositionSide.LONG:
            return (close_price - open_price) / open_price
        elif side == PositionSide.SHORT:
            return (open_price - close_price) / open_price
        elif side == PositionSide.FLAT:
            return Decimal()
        else:
            raise ValueError(f"Cannot calculate return "
                             f"(position side was {position_side_to_string(side)}).")
