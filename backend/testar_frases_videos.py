import base64
import glob
import os
import sys
import cv2
import numpy as np

# Testa o modelo das frases passando os vídeos de backend/videos_frases/
# pela API do mesmo jeito que o app faz (frames 320x240 a cada 200ms).
# Uso: python backend/testar_frases_videos.py
# Atenção: se os vídeos foram usados no treino, o resultado é otimista.

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
import main
from frases import DURACAO_SEGUNDOS


def ler(video):
    cap = cv2.VideoCapture(video)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    frames = []
    while True:
        ok, f = cap.read()
        if not ok:
            break
        frames.append(f)
    return frames, fps


def enviar(frames, fps, inicio, duracao, espelho=False, maximo=None):
    idx = [int(round((inicio + t / 1000) * fps)) for t in range(0, int(duracao * 1000), 200)]
    idx = [i for i in idx if 0 <= i < len(frames)]
    if maximo:
        idx = [idx[int(k)] for k in np.linspace(0, len(idx) - 1, maximo)]
    imagens = []
    for i in idx:
        f = cv2.resize(frames[i], (320, 240))
        if espelho:
            f = cv2.flip(f, 1)
        imagens.append(base64.b64encode(cv2.imencode('.jpg', f, [cv2.IMWRITE_JPEG_QUALITY, 70])[1]).decode())
    r = main.reconhecer_frase(main.SequenciaRequest(
        imagens=imagens, tempos_ms=[(i - idx[0]) * 1000 / fps for i in idx]))
    return f"{r['frase'] or '(nada)'} {r['confianca']:.2f}".ljust(20)


acertos = total = 0
for video in sorted(glob.glob('backend/videos_frases/*/*.*')):
    esperado = os.path.basename(os.path.dirname(video))
    frames, fps = ler(video)
    # Janela centralizada no vídeo, como se a pessoa sinalizasse depois da contagem
    inicio = max(0.0, (len(frames) / fps - DURACAO_SEGUNDOS) / 2)
    resultados = [enviar(frames, fps, inicio, DURACAO_SEGUNDOS),
                  enviar(frames, fps, inicio, DURACAO_SEGUNDOS, espelho=True),
                  enviar(frames, fps, inicio, DURACAO_SEGUNDOS, maximo=6)]
    for r in resultados:
        total += 1
        acertos += r.startswith(esperado)
    print(f"{esperado:14s} {os.path.basename(video):16s} normal: {resultados[0]} "
          f"espelhado: {resultados[1]} 6 frames: {resultados[2]}")
print(f"\nAcertos: {acertos}/{total}")
