from zeromq_connector import DWX_ZeroMQ_Connector
from time import sleep
from collections import deque
from preproc import *

import pandas as pd
import time
import zmq

#bar_count = 100
#timeframe = 60
#symbol = 'DOGUSD'

def get_hist_data_chunks(bar_count, timeframe, symbol, PUSH, PULL, SUB, chunk_size=30):
    """
    Fetch market data in chunks to avoid memory overload.

    Args:
        bar_count (int): Total number of candles requested.
        timeframe (int): Timeframe in minutes (e.g., 15, 60, 240, 1440).
        symbol (str): Market symbol (e.g., 'US2000').
        PUSH, PULL, SUB (int): MetaTrader connection ports.
        chunk_size (int): Number of candles per batch.

    Yields:
        DataFrame: A chunk of candles (30 rows at a time).
    """
    # Connect to MetaTrader
    try:
        connector = DWX_ZeroMQ_Connector(_PUSH_PORT=PUSH, _PULL_PORT=PULL, _SUB_PORT=SUB)
        columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']

        # Request all candles at once
        connector._DWX_MTX_SEND_HIST_REQUEST_2(symbol, timeframe, 0, bar_count)
        sleep(2)

        if connector._History_DB:
            data_window = connector._History_DB[symbol]
            sorted_data_window = pd.DataFrame(data_window, columns=columns)

            # Yield small chunks of candles (30 at a time)
            for i in range(0, len(sorted_data_window)):
                if i + chunk_size - 1 < len(sorted_data_window):
                    yield sorted_data_window.iloc[i:i + chunk_size - 1]
                else:
                    break
        else:
            print("[INFO] No se han recibido datos aún...")
    except KeyboardInterrupt:
        print("\n[INFO] Script detenido por el usuario.")
    except Exception as e:
        print(f"[ERROR] Ocurrió un error: {str(e)}")
    finally:
        # Asegúrate de apagar el conector correctamente
        connector._DWX_ZMQ_SHUTDOWN_()
        print("\n\n[INFO] Conector cerrado.\n\n")


def get_hist_data(bar_count, timeframe, symbol, PUSH, PULL, SUB):
    try:
        # Inicializa el conector
        connector = DWX_ZeroMQ_Connector(_PUSH_PORT=PUSH, _PULL_PORT=PULL, _SUB_PORT=SUB)
        columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']
        data_window = []
        
        # Mantén el script en un bucle mientras obtiene y formatea datos usando pandas
        while True:
            #evt = zmq.utils.monitor.recv_monitor_message(monitor)
            #print(evt)

            # conecta y pide datos historicos usando numero de barras.
            connector._DWX_MTX_SEND_HIST_REQUEST_2(symbol, timeframe, 0, bar_count)
            sleep(2)
            # monitor = connector._PULL_SOCKET.get_monitor_socket()

            # Revisa si hay datos en Market_Data_DB
            if connector._History_DB:
                data_window = connector._History_DB[symbol]
                sorted_data_window = pd.DataFrame(data_window, columns=columns)
                return sorted_data_window
            else:
                print("[INFO] No se han recibido datos aún..." + "")

    
    except KeyboardInterrupt:
        print("\n[INFO] Script detenido por el usuario.")
    except Exception as e:
        print(f"[ERROR] Ocurrió un error: {str(e)}")
    finally:
        # Asegúrate de apagar el conector correctamente
        connector._DWX_ZMQ_SHUTDOWN_()
        print("[INFO] Conector cerrado.")


def init_live_data_rolling(rolling_window, window_size, timeframe, symbol, PUSH, PULL, SUB):
    """
    Fetch and maintain a rolling window of market data.

    Args:
        rolling_window (deque): The actual variable created in the main function.
        window_size (int): Number of candles to keep in the rolling window.
        timeframe (int): Timeframe in minutes (e.g., 15, 60, 240, 1440).
        symbol (str): Market symbol (e.g., 'US2000').
        PUSH, PULL, SUB (int): MetaTrader connection ports.

    returns:
        DataFrame: The latest rolling window of candles (30 rows at a time).
        rolling_window (deque): after adding the initial data
    """
    try:
        # Connect to MetaTrader
        connector = DWX_ZeroMQ_Connector(_PUSH_PORT=PUSH, _PULL_PORT=PULL, _SUB_PORT=SUB)
        columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']


        # Request all candles at once
        connector._DWX_MTX_SEND_HIST_REQUEST_2(symbol, timeframe, 0, window_size)
        sleep(2)

        if connector._History_DB:
            data_window = connector._History_DB[symbol]
            sorted_data_window = pd.DataFrame(data_window, columns=columns)

            # Fill the deque with initial data
            for i in range(len(sorted_data_window)):
                rolling_window.append(sorted_data_window.iloc[i])  # Add new row, oldest auto-removed

                # Yield only when we reach the required window size
                if len(rolling_window) == window_size:
                    return pd.DataFrame(rolling_window, columns=columns), rolling_window  # Convert deque to DataFrame

        else:
            print("[INFO] No se han recibido datos aún...")

    except KeyboardInterrupt:
        print("\n[INFO] Script detenido por el usuario.")
    except Exception as e:
        print(f"[ERROR] Ocurrió un error: {str(e)}")
    finally:
        # Shutdown connector properly
        connector._DWX_ZMQ_SHUTDOWN_()
        print("\n\n[INFO] Conector cerrado.\n\n")


def update_rolling_window(rolling_window, timeframe, symbol, PUSH, PULL, SUB):
    """
    Fetches the latest candle and updates the rolling window.

    Args:
        rolling_window (deque): The existing rolling window of candles.
        timeframe (int): Timeframe in minutes (e.g., 15, 60, 240, 1440).
        symbol (str): Market symbol (e.g., 'US2000').
        PUSH, PULL, SUB (int): MetaTrader connection ports.

    Returns:
        DataFrame: Updated rolling window with the new candle.
        rolling_window (deque): Updated rolling window.
    """
    try:
        # Connect to MetaTrader
        connector = DWX_ZeroMQ_Connector(_PUSH_PORT=PUSH, _PULL_PORT=PULL, _SUB_PORT=SUB)

        # Request the latest single candle
        connector._DWX_MTX_SEND_HIST_REQUEST_2(symbol, timeframe, 0, 1)
        sleep(2)

        if connector._History_DB:
            # Get the last candle
            new_candle = connector._History_DB[symbol][-1]  # Get the most recent candle

            # Convert it to Pandas Series
            columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']
            latest_candle = pd.Series(new_candle, index=columns)

            # take into account if the current candle has changed or not
            if latest_candle['Date'] != rolling_window[-1]['Date']:
                # Append the new candle, deque automatically removes the oldest
                rolling_window.append(latest_candle)

            # Convert deque to DataFrame and return updated rolling window
            return pd.DataFrame(rolling_window, columns=['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']), rolling_window

        else:
            print("[INFO] No se ha recibido una nueva vela...")
            return pd.DataFrame(rolling_window, columns=['Date', 'Open', 'High', 'Low', 'Close', 'Volume', 'RSI', 'EMA20']), rolling_window

    except KeyboardInterrupt:
        print("\n[INFO] Script detenido por el usuario.")
    except Exception as e:
        print(f"[ERROR] Ocurrió un error: {str(e)}")
        return pd.DataFrame(rolling_window, columns=['Date', 'Open', 'High', 'Low', 'Close', 'Volume'])
    finally:
        # Shutdown connector properly
        connector._DWX_ZMQ_SHUTDOWN_()
        print("\n\n[INFO] Conector cerrado.\n\n")


# 🔹 Obtener datos en tiempo real desde MetaTrader
def get_market_data_sr(symbol='BTCUSD'):

    start_time = time.time()

    # Cargar los datos históricos (todas las temporalidades)
    US2000_data_15   = get_hist_data(300, 15, symbol, 32768, 32769, 32770)
    US2000_data_60   = get_hist_data(200, 60, symbol, 32768, 32769, 32770)
    US2000_data_240  = get_hist_data(200, 240, symbol, 32768, 32769, 32770)
    US2000_data_1440 = get_hist_data(200, 1440, symbol, 32768, 32769, 32770)

    # 🔹 Soportes y resistencias en todas las temporalidades
    D1_sr_high, D1_sr_low, D1_sr_close, D1_sr_volume = sr_kmeans(US2000_data_1440, 12, 5, 3, 6)
    H4_sr_high, H4_sr_low, H4_sr_close, H4_sr_volume = sr_kmeans(US2000_data_240, 12, 5, 3, 6)
    H1_sr_high, H1_sr_low, H1_sr_close, H1_sr_volume = sr_kmeans(US2000_data_60, 12, 5, 3, 6)
    M15_sr_high, M15_sr_low, M15_sr_close, M15_sr_volume = sr_kmeans(US2000_data_15, 12, 5, 3, 6)

    end_time = time.time()
    execution_time = end_time - start_time
    print("\n\n  Support & Ressistance exec time: " + str(execution_time) + "\n\n")

    suppres_levels = {
        "SupportResistance": {
            "M15": {"Low": M15_sr_low,
                    "High": M15_sr_high,
                    "Close": M15_sr_close,
                    "Volume": M15_sr_volume
                    },
            "H1": {"Low": H1_sr_low,
                   "High": H1_sr_high,
                   "Close": H1_sr_close,
                   "Volume": H1_sr_volume
                   },
            "H4": {"Low": H4_sr_low,
                   "High": H4_sr_high,
                   "Close": H4_sr_close,
                   "Volume": H4_sr_volume
                   },
            "D1": {"Low": D1_sr_low,
                   "High": D1_sr_high,
                   "Close": D1_sr_close,
                   "Volume": D1_sr_volume
                   }
        }
    }

    return suppres_levels


# Log Returns calculation for noise modeling on the signals

def log_returns(prices: pd.Series) -> pd.Series:
    """
    Compute the logarithmic returns of a given price series.

    Args:
        prices (pd.Series): Time series of asset prices.

    Returns:
        pd.Series: Logarithmic returns.
    """
    return np.log(prices / prices.shift(1))