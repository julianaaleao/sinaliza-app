import numpy as np

from normalizacao import normalizar_landmarks

# Frases em LIBRAS reconhecidas pelo LSTM de duas mãos.
# O id é o nome da pasta em backend/dados_frases/ e o que a API devolve;
# o texto e as respostas ficam no app (lib/frases.dart).
FRASES = [
    'OLA_TUDO_BEM',
    'QUAL_SEU_NOME',
    'ONDE_BANHEIRO',
    'QUANTO_CUSTA',
    'QUE_HORAS',
    'NENHUM',
]

FRAMES_POR_SEQ = 30
DURACAO_SEGUNDOS = 5.0  # tempo de gravação de cada frase (coleta e app)
N_CARACTERISTICAS = 2 * 66


def maos_do_resultado(result):
    """Resultado do MediaPipe -> array (2, 63) com NaN onde não tem mão.
    Posição 0 = mão marcada como 'Right', 1 = 'Left'."""
    maos = np.full((2, 63), np.nan)
    for landmarks, lado in zip(result.hand_landmarks, result.handedness):
        pos = 0 if lado[0].category_name == 'Right' else 1
        if not np.isnan(maos[pos, 0]):
            pos = 1 - pos  # duas mãos com o mesmo lado: usa a posição livre
        maos[pos] = [v for p in landmarks for v in (p.x, p.y, p.z)]
    return maos


def espelhar(seq):
    """Espelha horizontalmente (como câmera frontal) e troca as mãos de lugar.
    Usado no treino para o modelo funcionar com imagem espelhada e canhotos."""
    seq = np.array(seq, dtype=np.float64)
    seq[:, :, 0::3] = 1.0 - seq[:, :, 0::3]
    return seq[:, ::-1, :]


def reamostrar_maos(seq, tempos=None, n=FRAMES_POR_SEQ):
    """(m, 2, 63) com NaN -> (n, 2, 63) igualmente espaçado no tempo."""
    seq = np.asarray(seq, dtype=np.float64)
    if tempos is None:
        tempos = np.arange(len(seq), dtype=np.float64)
    tempos = np.asarray(tempos, dtype=np.float64)
    alvo = np.linspace(tempos[0], tempos[-1], n)
    saida = np.full((n, 2, 63), np.nan)
    for m in range(2):
        presente = ~np.isnan(seq[:, m, 0])
        if presente.sum() == 0:
            continue
        # Fração de frames com a mão por perto: só mantém a mão onde ela aparecia
        visivel = np.interp(alvo, tempos, presente.astype(np.float64)) >= 0.5
        t = tempos[presente]
        for k in range(63):
            saida[:, m, k] = np.interp(alvo, t, seq[presente, m, k])
        saida[~visivel, m] = np.nan
    return saida


def caracteristicas_maos(seq):
    """(n, 2, 63) -> (n, 132). Para cada mão: forma normalizada (63),
    posição do pulso em relação ao centro do gesto, em tamanhos de mão (2),
    e se a mão está visível (1)."""
    seq = np.asarray(seq, dtype=np.float64)
    n = len(seq)
    pontos = seq.reshape(n, 2, 21, 3)
    presente = ~np.isnan(pontos[:, :, 0, 0])
    if not presente.any():
        return np.zeros((n, N_CARACTERISTICAS))

    tamanhos = np.max(np.linalg.norm(pontos[:, :, :, :2] - pontos[:, :, :1, :2], axis=3), axis=2)
    escala = max(float(np.median(tamanhos[presente])), 1e-6)
    pulsos = pontos[:, :, 0, :2]
    centro = pulsos[presente].mean(axis=0)

    partes = []
    for m in range(2):
        formas = np.zeros((n, 63))
        movimento = np.zeros((n, 2))
        for i in np.where(presente[:, m])[0]:
            formas[i] = normalizar_landmarks(seq[i, m])
            movimento[i] = (pulsos[i, m] - centro) / escala
        partes += [formas, movimento, presente[:, m:m + 1].astype(np.float64)]
    return np.hstack(partes)


def preparar_frase(seq, tempos=None):
    """Frames com as duas mãos -> entrada do LSTM, ou None se quase não teve mão."""
    seq = np.asarray(seq, dtype=np.float64)
    if (~np.isnan(seq[:, :, 0])).any(axis=1).sum() < 2:
        return None
    return caracteristicas_maos(reamostrar_maos(seq, tempos))
