# -------------------------------------------------------------------------------------------------
# <copyright file="data.pyx" company="Nautech Systems Pty Ltd">
#  Copyright (C) 2015-2019 Nautech Systems Pty Ltd. All rights reserved.
#  The use of this source code is governed by the license as found in the LICENSE.md file.
#  http://www.nautechsystems.io
# </copyright>
# -------------------------------------------------------------------------------------------------

import iso8601
import msgpack

from bson import BSON
from bson.raw_bson import RawBSONDocument
from decimal import Decimal

from nautilus_trader.core.precondition cimport Precondition
from nautilus_trader.model.objects cimport Symbol, Price, BarSpecification, Bar, BarType, Tick, Instrument, Quantity
from nautilus_trader.model.enums import Broker, Venue, Currency, OrderSide, OrderType, TimeInForce, SecurityType
from nautilus_trader.model.c_enums.venue cimport venue_string
from nautilus_trader.model.c_enums.brokerage cimport Broker, broker_string
from nautilus_trader.model.c_enums.time_in_force cimport TimeInForce, time_in_force_string
from nautilus_trader.model.c_enums.order_side cimport OrderSide, order_side_string
from nautilus_trader.model.c_enums.order_type cimport OrderType, order_type_string
from nautilus_trader.model.c_enums.currency cimport Currency, currency_string
from nautilus_trader.model.c_enums.security_type cimport SecurityType, security_type_string
from nautilus_trader.model.identifiers cimport InstrumentId
from nautilus_trader.serialization.constants cimport *
from nautilus_trader.serialization.base cimport DataSerializer, InstrumentSerializer
from nautilus_trader.serialization.common cimport *



cpdef Tick deserialize_tick(Symbol symbol, bytes tick_bytes):
    """
    Return a deserialized tick from the given symbol and bytes.

    :param symbol: The ticks symbol.
    :param tick_bytes: The tick bytes to deserialize.
    :return: Tick.
    """
    cdef list values = tick_bytes.decode(UTF8).split(',')

    return Tick(
        symbol,
        Price(values[0]),
        Price(values[1]),
        iso8601.parse_date(values[2]))

cpdef Bar deserialize_bar(bytes bar_bytes):
    """
    Return the deserialized bar from the give bytes.
    
    :param bar_bytes: The bar bytes to deserialize.
    :return: Bar.
    """
    cdef list values = bar_bytes.decode(UTF8).split(',')

    return Bar(
        Price(values[0]),
        Price(values[1]),
        Price(values[2]),
        Price(values[3]),
        Quantity(values[4]),
        iso8601.parse_date(values[5]))

cpdef list deserialize_bars(bytes[:] bar_bytes_array):
    """
    Return a list of deserialized bars from the given bars bytes.
    
    :param bar_bytes_array: The bar bytes to deserialize.
    :return: List[Bar].
    """
    cdef list bars = []
    cdef int i
    cdef int array_length = len(bar_bytes_array)
    for i in range(array_length):
        bars.append(deserialize_bar(bar_bytes_array[i]))

    return bars


cdef class BsonInstrumentSerializer(InstrumentSerializer):
    """
    Provides an instrument serializer for the MessagePack specification.
    """

    cpdef bytes serialize(self, Instrument instrument):
        """
        Return the MessagePack specification bytes serialized from the given instrument.

        :param instrument: The instrument to serialize.
        :return: bytes.
        """
        return bytes(RawBSONDocument(BSON.encode({
            ID: instrument.id.value,
            SYMBOL: instrument.symbol.value,
            BROKER_SYMBOL: instrument.broker_symbol,
            QUOTE_CURRENCY: currency_string(instrument.quote_currency),
            SECURITY_TYPE: security_type_string(instrument.security_type),
            TICK_PRECISION: instrument.tick_precision,
            TICK_SIZE: str(instrument.tick_size),
            ROUND_LOT_SIZE: instrument.round_lot_size.value,
            MIN_STOP_DISTANCE_ENTRY: instrument.min_stop_distance_entry,
            MIN_STOP_DISTANCE: instrument.min_stop_distance,
            MIN_LIMIT_DISTANCE_ENTRY: instrument.min_limit_distance_entry,
            MIN_LIMIT_DISTANCE: instrument.min_limit_distance,
            MIN_TRADE_SIZE: instrument.min_trade_size.value,
            MAX_TRADE_SIZE: instrument.max_trade_size.value,
            ROLL_OVER_INTEREST_BUY: str(instrument.rollover_interest_buy),
            ROLL_OVER_INTEREST_SELL: str(instrument.rollover_interest_sell),
            TIMESTAMP: convert_datetime_to_string(instrument.timestamp),
        })).raw)

    cpdef Instrument deserialize(self, bytes instrument_bytes):
        """
        Return the instrument deserialized from the given MessagePack specification bytes.

        :param instrument_bytes: The bytes to deserialize.
        :return: Instrument.
        """
        cdef dict deserialized = BSON.decode(instrument_bytes)

        return Instrument(
            instrument_id=InstrumentId(deserialized[ID]),
            symbol=parse_symbol(deserialized[SYMBOL]),
            broker_symbol=deserialized[BROKER_SYMBOL],
            quote_currency=Currency[(deserialized[QUOTE_CURRENCY])],
            security_type=SecurityType[(deserialized[SECURITY_TYPE])],
            tick_precision=deserialized[TICK_PRECISION],
            tick_size=Decimal(deserialized[TICK_SIZE]),
            round_lot_size=Quantity(deserialized[ROUND_LOT_SIZE]),
            min_stop_distance_entry=deserialized[MIN_STOP_DISTANCE_ENTRY],
            min_stop_distance=deserialized[MIN_STOP_DISTANCE],
            min_limit_distance_entry=deserialized[MIN_LIMIT_DISTANCE_ENTRY],
            min_limit_distance=deserialized[MIN_LIMIT_DISTANCE],
            min_trade_size=Quantity(deserialized[MIN_TRADE_SIZE]),
            max_trade_size=Quantity(deserialized[MAX_TRADE_SIZE]),
            rollover_interest_buy=Decimal(deserialized[ROLL_OVER_INTEREST_BUY]),
            rollover_interest_sell=Decimal(deserialized[ROLL_OVER_INTEREST_SELL]),
            timestamp=convert_string_to_datetime(deserialized[TIMESTAMP]))


cdef class DataMapper:
    """
    Provides a data mapper for data objects.
    """

    cpdef dict map_ticks(self, list ticks):
        Precondition.not_empty(ticks, 'ticks')
        Precondition.type(ticks[0], Tick, 'ticks')


        cdef dict data = {
            'DataType': type(ticks[0]).__name__,
            'Symbol': ticks[0].symbol.value,
            'Values': [str(tick) for tick in ticks]
        }

        return data

    cpdef dict map_bars(self, list bars, BarType bar_type):
        Precondition.not_empty(bars, 'bars')
        Precondition.type(bars[0], Bar, 'bars')

        cdef dict data = {
            'DataType': type(bars[0]).__name__,
            'BarType': str(bar_type),
            'Values': [str(bar) for bar in bars]
        }

        return data

    cpdef dict map_instruments(self, list instruments):
        Precondition.not_empty(instruments, 'instruments')
        Precondition.type(instruments[0], Instrument, 'instruments')

        cdef dict data = {
            'DataType': type(instruments[0]).__name__,
        }

        return data


cdef class BsonDataSerializer(DataSerializer):
    """
    Provides a serializer for data objects for the BSON specification.
    """

    cpdef bytes serialize(self, dict data):
        """
        Serialize the given data to bytes.

        :param: data: The data to serialize.
        :return: bytes.
        :raises: ValueError: If the data is empty.
        """
        Precondition.not_empty(data, 'data')

        return bytes(RawBSONDocument(BSON.encode(data)).raw)

    cpdef dict deserialize(self, bytes data_bytes):
        """
        Deserialize the given bytes to a data object.

        :param: data_bytes: The data bytes to deserialize.
        :return: Dict.
        """
        return BSON.decode(data_bytes)
