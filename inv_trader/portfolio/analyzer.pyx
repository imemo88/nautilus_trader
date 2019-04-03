#!/usr/bin/env python3
# -------------------------------------------------------------------------------------------------
# <copyright file="analyzer.pyx" company="Invariance Pte">
#  Copyright (C) 2018-2019 Invariance Pte. All rights reserved.
#  The use of this source code is governed by the license as found in the LICENSE.md file.
#  http://www.invariance.com
# </copyright>
# -------------------------------------------------------------------------------------------------

# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False

import pandas as pd

from math import log
from cpython.datetime cimport date, datetime, timedelta

from inv_trader.enums.order_side cimport OrderSide
from inv_trader.model.events cimport AccountEvent
from inv_trader.model.objects cimport Money
from inv_trader.model.identifiers cimport GUID


cdef class Analyzer:
    """
    Represents a trading portfolio analyzer for generating performance metrics
    and statistics.
    """

    def __init__(self, log_returns=False):
        """
        Initializes a new instance of the Analyzer class.

        :param log_returns: A boolean flag indicating whether log returns will be used.
        """
        self._log_returns = log_returns
        self._returns = pd.Series()
        self._positions = pd.DataFrame(columns=['cash'])
        self._transactions = pd.DataFrame(columns=['amount'])
        #self._transactions = pd.DataFrame(columns=['amount', 'price', 'symbol'])
        self._equity_curve = pd.DataFrame(columns=['capital'])
        self._account_capital = Money.zero()
        self._account_initialized = False

    cpdef void add_return(self, datetime time, float value):
        """
        Add return data to the analyzer.
        
        :param time: The timestamp for the returns entry.
        :param value: The return value to add.
        """
        if self._log_returns:
            value = log(value)

        cdef date index_date = pd.to_datetime(time.date())
        if index_date not in self._returns:
            self._returns.loc[index_date] = 0.0

        self._returns.loc[index_date] += value

    cpdef void add_positions(
            self,
            datetime time,
            list positions,
            Money cash_balance):
        """
        Add end of day positions data to the analyzer.

        :param time: The timestamp for the positions entry.
        :param positions: The end of day positions.
        :param cash_balance: The end of day cash balance of the account.
        """
        cdef date index_date = pd.to_datetime(time.date())
        if index_date not in self._positions:
            self._positions.loc[index_date] = 0

        cdef str symbol
        cdef list columns
        for position in positions:
            symbol = str(position.symbol)
            columns = list(self._positions.columns.values)
            if symbol not in columns:
                self._positions[symbol] = 0
            self._positions.loc[index_date][symbol] += position.relative_quantity

        # TODO: Cash not being added??
        self._positions.loc[index_date]['cash'] = cash_balance.value

    cpdef void add_transaction(self, AccountEvent event):
        """
        Add a transaction to the analyzer.
        
        :param event: The account event for the transaction.
        """
        if not self._account_initialized:
            self._account_capital = event.cash_balance
            self._account_initialized = True
            return

        cdef Money pnl = event.cash_balance - self._account_capital
        self._equity_curve[event.timestamp] = pnl

    # cpdef void add_transaction(self, OrderEvent event):
    #     """
    #     Add transaction data to the analyzer.
    #
    #     :param event: The transaction event.
    #     """
    #     cdef datetime index_datetime = pd.to_datetime(event.timestamp)
    #     if index_datetime in self._transactions:
    #         index_datetime += timedelta(milliseconds=1)
    #
    #     cdef int quantity
    #     if event.order_side == OrderSide.BUY:
    #         quantity = event.filled_quantity.value
    #     else:
    #         quantity = -event.filled_quantity.value
    #
    #     self._transactions.loc[index_datetime] = [quantity, str(event.average_price), str(event.symbol)]

    cpdef object get_returns(self):
        """
        Return the returns data.
        
        :return: Pandas.Series.
        """
        return self._returns

    cpdef object get_positions(self):
        """
        Return the positions data.
        
        :return: Pandas.DataFrame.
        """
        return self._positions

    cpdef object get_transactions(self):
        """
        Return the transactions data.
        
        :return: Pandas.DataFrame.
        """
        return self._transactions

    cpdef void create_returns_tear_sheet(self):
        """
        Create a pyfolio returns tear sheet based on analyzer data from the last run.
        """
        # Do nothing

    cpdef void create_full_tear_sheet(self):
        """
        Create a pyfolio full tear sheet based on analyzer data from the last run.
        """
        # Do nothing
