import pandas as pd
import numpy as np
import cupy as cp
import matplotlib.pyplot as plt
from tslearn.clustering import TimeSeriesKMeans
from tslearn.metrics import dtw
from tslearn.preprocessing import TimeSeriesScalerMeanVariance



def sr_kmeans(data, dev, dep, back, clusters):
    high_highs, high_lows, low_highs, low_lows, close_highs, close_lows, vol_highs, vol_lows = zigzag_all(data, dev, dep, back)
    high_points = high_highs + high_lows
    low_points = low_highs + low_lows
    close_points = close_highs + close_lows
    vol_points = vol_highs + vol_lows

    high_labels, high_centroids = kmeans_dtw(high_points, clusters)
    low_labels, low_centroids = kmeans_dtw(low_points, clusters)
    close_labels, close_centroids = kmeans_dtw(close_points, clusters)
    vol_labels, vol_centroids = kmeans_dtw(vol_points, 5)

    high_flatten = high_centroids.flatten().tolist()
    high_flatten = [x for x in high_flatten if x!=0]
    low_flatten = low_centroids.flatten().tolist()
    low_flatten = [x for x in low_flatten if x != 0]
    close_flatten = close_centroids.flatten().tolist()
    close_flatten = [x for x in close_flatten if x != 0]
    vol_flatten = vol_centroids.flatten().tolist()
    vol_flatten = [x for x in vol_flatten if x != 0]

    return high_flatten, low_flatten, close_flatten, vol_flatten

def kmeans_dtw(data, clusters):
    series = np.array([data])
    series = series.reshape(-1, 1, 1)

    #Clustering con k-means y DWT
    model = TimeSeriesKMeans(n_clusters=clusters, metric="dtw", verbose=True)
    labels = model.fit_predict(series)
    centroids = model.cluster_centers_
    return labels, centroids
    #for i, centroid in enumerate(centroids):
    #    plt.axhline(centroid.flatten()[0], color=f"C{i}", linestyle="--", label=f"Centroide Cluster {i}")

    #plt.title("Clustering con Centroides como Soportes/Resistencias")
    #plt.xlabel("Índice de Punto")
    #plt.ylabel("Precio")
    #plt.legend()
    #plt.grid()
    #plt.show()



def zigzag_all(data, dev, dep, back):
    high_highs  = [] # Maximos locales en el high
    high_lows   = [] # Minimos locales en el high
    low_highs   = [] # Maximos locales en el low
    low_lows    = [] # Minimos locales en el low
    close_highs = [] # Minimos locales en el close
    close_lows  = [] # Minimos locales en el close
    open_highs  = [] # Minimos locales en el open
    open_lows   = [] # Minimos locales en el open

    test = data['High'][:]

    high_zigzag, high_highs, high_lows = zigzag(data['High'][:], dev, dep, back)
    low_zigzag, low_highs, low_lows = zigzag(data['Low'][:], dev, dep, back)
    close_zigzag, close_highs, close_lows = zigzag(data['Close'][:], dev, dep, back)
    vol_zigzag, vol_highs, vol_lows = zigzag(data['Volume'][:], dev, dep, back)

    #zigzag_plot(data, "High", high_highs, high_lows, high_zigzag, "High ZIGZAG")
    #zigzag_plot(data, "Low", low_highs, low_lows, low_zigzag, "Low ZIGZAG")
    #zigzag_plot(data, "Close", close_highs, close_lows, close_zigzag, "Close ZIGZAG")
    #zigzag_plot(data, "Open", open_highs, open_lows, open_zigzag, "Open ZIGZAG")

    return high_highs, high_lows, low_highs, low_lows, close_highs, close_lows, vol_highs, vol_lows #, open_highs, open_lows


def zigzag(prices, depth=12, deviation=5, backstep=3):
    """
    Implementación del indicador ZigZag en Python.

    :param prices: Serie de precios (lista o pandas.Series).
    :param depth: Profundidad para buscar máximos/mínimos.
    :param deviation: Desviación mínima para considerar un nuevo extremo (en porcentaje).
    :param backstep: Velas para confirmar extremos.
    :return: Lista con valores ZigZag.
    """
    # Buffers
    high_buffer = [0] * len(prices)
    low_buffer = [0] * len(prices)
    zigzag_buffer = [0] * len(prices)

    # Variables auxiliares
    last_high, last_low = None, None
    last_high_pos, last_low_pos = -1, -1

    # Proceso principal
    for i in range(depth, len(prices)):
        # Encontrar el máximo y mínimo local en la profundidad
        local_high = max(prices[i - depth:i + 1])
        local_low = min(prices[i - depth:i + 1])

        # Verificar si el máximo es significativo
        if last_high is None or (local_high - prices[i] > deviation / 100 * prices[i]):
            last_high = local_high
            last_high_pos = i

            # Eliminar máximos anteriores dentro del backstep
            for j in range(1, backstep + 1):
                if i - j >= 0 and high_buffer[i - j] > last_high:
                    high_buffer[i - j] = 0

            high_buffer[i] = last_high

        # Verificar si el mínimo es significativo
        if last_low is None or (prices[i] - local_low > deviation / 100 * prices[i]):
            last_low = local_low
            last_low_pos = i

            # Eliminar mínimos anteriores dentro del backstep
            for j in range(1, backstep + 1):
                if i - j >= 0 and low_buffer[i - j] < last_low:
                    low_buffer[i - j] = 0

            low_buffer[i] = last_low

        # Actualizar el ZigZag Buffer
        if high_buffer[i] != 0:
            zigzag_buffer[i] = high_buffer[i]
        elif low_buffer[i] != 0:
            zigzag_buffer[i] = low_buffer[i]

    return zigzag_buffer, high_buffer, low_buffer


# Función para confirmar puntos basados en retroceso
def confirm_points(points, df, back):
    confirmed = []
    for idx, price in points:
        # Confirmar que sea un máximo/mínimo válido mirando hacia atrás
        valid = True
        for j in range(1, back + 1):
            if idx - j >= 0:
                if price < df[idx - j]:  # Si es un máximo
                    valid = False
                    break
                if price > df[idx - j]:  # Si es un mínimo
                    valid = False
                    break
        if valid:
            confirmed.append((idx, price))
    return confirmed

def zigzag_plot(df, buffer, highs, lows, zigzag, title):


    highs_nonzero = list(filter(lambda val: val[1] != 0, zip(df["Date"], highs)))
    lows_nonzero = list(filter(lambda val: val[1] != 0, zip(df["Date"], lows)))
    filtered_dates, filtered_highs = zip(*highs_nonzero)
    filtered_dates2, filtered_lows = zip(*lows_nonzero)
    plt.figure(figsize=(12, 6))

    plt.plot(df["Date"], df[buffer], label=buffer, color="blue", alpha=0.5)

    plt.scatter(filtered_dates,
                filtered_highs,
                color="red",
                label="Máximos (Highs)",
                zorder=5)

    plt.scatter(filtered_dates2,
                filtered_lows,
                color="green",
                label="Mínimos (Lows)",
                zorder=5)
    #plt.plot(df["Date"], zigzag, label="ZigZag", color="orange")

    plt.title(title)
    plt.xlabel("Fecha")
    plt.ylabel("Precio de Cierre")
    plt.legend()
    plt.grid()
    plt.show()