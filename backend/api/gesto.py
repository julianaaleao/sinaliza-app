import numpy as np

from normalizacao import normalizar_landmarks

# LSTM do gesto dinâmico rodando só com numpy (sem TensorFlow no servidor).
# Os pesos vêm do backend/treinar_lstm.py.

GESTOS = ['OI', 'NENHUM']
FRAMES_POR_SEQ = 30


def _sigmoid(x):
    return 1.0 / (1.0 + np.exp(-x))


class ModeloGesto:
    def __init__(self, caminho_pesos):
        p = np.load(caminho_pesos)
        self.lstms = []
        i = 0
        while f"lstm{i}_kernel" in p:
            self.lstms.append((p[f"lstm{i}_kernel"], p[f"lstm{i}_recorrente"], p[f"lstm{i}_bias"]))
            i += 1
        self.denses = []
        i = 0
        while f"dense{i}_kernel" in p:
            self.denses.append((p[f"dense{i}_kernel"], p[f"dense{i}_bias"]))
            i += 1

    @staticmethod
    def _lstm(x, kernel, recorrente, bias):
        # Mesma conta do Keras: portões na ordem i, f, c, o
        unidades = recorrente.shape[0]
        h = np.zeros(unidades)
        c = np.zeros(unidades)
        saidas = []
        for t in range(x.shape[0]):
            z = x[t] @ kernel + h @ recorrente + bias
            i = _sigmoid(z[:unidades])
            f = _sigmoid(z[unidades:2 * unidades])
            g = np.tanh(z[2 * unidades:3 * unidades])
            o = _sigmoid(z[3 * unidades:])
            c = f * c + i * g
            h = o * np.tanh(c)
            saidas.append(h)
        return np.array(saidas)

    def prever(self, sequencia):
        """sequencia: (30, 63) -> probabilidades de cada gesto."""
        x = np.asarray(sequencia, dtype=np.float64)
        for n, pesos in enumerate(self.lstms):
            x = self._lstm(x, *pesos)
            if n == len(self.lstms) - 1:
                x = x[-1]  # última camada LSTM devolve só o último passo
        for n, (kernel, bias) in enumerate(self.denses):
            x = x @ kernel + bias
            if n < len(self.denses) - 1:
                x = np.maximum(x, 0)  # relu
        x = np.exp(x - x.max())
        return x / x.sum()


def reamostrar(frames, tempos=None, n=FRAMES_POR_SEQ):
    """Converte os frames recebidos (quantos o celular conseguir capturar)
    em exatamente n frames igualmente espaçados no tempo, interpolando.

    frames: lista de 63 valores, ou None quando a mão não foi detectada.
    """
    if tempos is None:
        tempos = list(range(len(frames)))
    validos = [(t, f) for t, f in zip(tempos, frames) if f is not None]
    if len(validos) < 2:
        return None
    t = np.array([v[0] for v in validos], dtype=np.float64)
    f = np.array([v[1] for v in validos], dtype=np.float64)
    alvo = np.linspace(tempos[0], tempos[-1], n)
    return np.stack([np.interp(alvo, t, f[:, k]) for k in range(f.shape[1])], axis=1)


def caracteristicas(seq):
    """(n, 63) landmarks brutos -> (n, 65) entrada do LSTM:
    63 da forma da mão normalizada + 2 do movimento do pulso
    (em relação à posição média, medido em "tamanhos de mão")."""
    seq = np.asarray(seq, dtype=np.float64)
    formas = np.array([normalizar_landmarks(f) for f in seq])
    pontos = seq.reshape(len(seq), 21, 3)
    tamanhos = np.max(np.linalg.norm(pontos[:, :, :2] - pontos[:, :1, :2], axis=2), axis=1)
    escala = max(float(np.median(tamanhos)), 1e-6)
    pulso = pontos[:, 0, :2]
    movimento = (pulso - pulso.mean(axis=0)) / escala
    return np.hstack([formas, movimento])


def preparar_sequencia(frames, tempos=None):
    """Frames recebidos (com None onde não tinha mão) -> entrada do LSTM."""
    seq = reamostrar(frames, tempos)
    return None if seq is None else caracteristicas(seq)
