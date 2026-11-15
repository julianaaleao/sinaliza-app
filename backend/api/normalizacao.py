import numpy as np


def normalizar_landmarks(row):
    """Recebe os 63 valores (x, y, z dos 21 pontos) e devolve 63 valores
    independentes da posição e do tamanho da mão na imagem.

    - Translação: o pulso (ponto 0) vira a origem.
    - Escala: divide pela maior distância de um ponto até o pulso.
    """
    pontos = np.asarray(row, dtype=np.float64).reshape(21, 3)
    pontos = pontos - pontos[0]
    escala = np.max(np.linalg.norm(pontos[:, :2], axis=1))
    if escala > 0:
        pontos = pontos / escala
    return pontos.flatten()
