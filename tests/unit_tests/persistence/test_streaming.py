# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
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

import sys

import pytest

from nautilus_trader.adapters.betfair.providers import BetfairInstrumentProvider
from nautilus_trader.backtest.node import BacktestNode
from nautilus_trader.persistence.catalog import DataCatalog
from nautilus_trader.persistence.external.core import process_files
from tests.integration_tests.adapters.betfair.test_kit import BetfairTestStubs
from tests.test_kit import PACKAGE_ROOT
from tests.test_kit.mocks import data_catalog_setup


@pytest.mark.skipif(sys.platform == "win32", reason="test path broken on windows")
class TestPersistenceStreaming:
    def setup(self):
        data_catalog_setup()
        self.catalog = DataCatalog.from_env()
        self.fs = self.catalog.fs
        self._loaded_data_into_catalog()

    def _loaded_data_into_catalog(self):
        self.instrument_provider = BetfairInstrumentProvider.from_instruments([])
        result = process_files(
            glob_path=PACKAGE_ROOT + "/data/1.166564490*.bz2",
            reader=BetfairTestStubs.betfair_reader(instrument_provider=self.instrument_provider),
            instrument_provider=self.instrument_provider,
            catalog=self.catalog,
        )
        assert result
        data = (
            self.catalog.instruments(as_nautilus=True)
            + self.catalog.instrument_status_updates(as_nautilus=True)
            + self.catalog.trade_ticks(as_nautilus=True)
            + self.catalog.order_book_deltas(as_nautilus=True)
            + self.catalog.ticker(as_nautilus=True)
        )
        return data

    def test_feather_writer(self):
        # Arrange
        instrument = self.catalog.instruments(as_nautilus=True)[0]
        run_config = BetfairTestStubs.betfair_backtest_run_config(
            catalog_path=str(self.catalog.path),
            catalog_fs_protocol=self.catalog.fs.protocol,
            instrument_id=instrument.id.value,
        )
        node = BacktestNode()

        # Act
        node.run_sync(run_configs=[run_config])

        # Assert
        result = self.catalog.read_backtest(backtest_run_id=run_config.id)
        assert len(result) == 3521
