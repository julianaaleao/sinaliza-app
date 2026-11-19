"""Mede o tempo de cada etapa da API, sem servidor HTTP (só o processamento).
Não altera nada no projeto: lê os vídeos de referência e escreve só em relatorio_tg/.
Uso: python relatorio_tg/scripts/medir_latencia.py
"""
import base64, csv, os, sys, time, platform
import cv2
import numpy as np

sys.path.insert(0, 'backend/api')
import main  # carrega os mesmos modelos e detectores da API
from normalizacao import normalizar_landmarks
from gesto import preparar_sequencia
from frases import maos_do_resultado, preparar_frase
import mediapipe as mp

REPETICOES = 20


def frames_jpeg(video, n, passo):
    cap = cv2.VideoCapture(video)
    todos = []
    while True:
        ok, f = cap.read()
        if not ok:
            break
        todos.append(f)
    sel = todos[10:10 + n * passo:passo]
    return [base64.b64encode(cv2.imencode('.jpg', cv2.resize(f, (320, 240)),
                                           [cv2.IMWRITE_JPEG_QUALITY, 70])[1]).decode() for f in sel]


def etapas(imagens, detector, modo):
    t = {}
    a = time.perf_counter()
    rgbs = []
    for img in imagens:
        frame = cv2.imdecode(np.frombuffer(base64.b64decode(img), np.uint8), cv2.IMREAD_COLOR)
        rgbs.append(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    t['decodificacao'] = time.perf_counter() - a
    a = time.perf_counter()
    res = [detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=r)) for r in rgbs]
    t['mediapipe'] = time.perf_counter() - a
    a = time.perf_counter()
    if modo == 'vogais':
        frames = [[v for p in r.hand_landmarks[0] for v in (p.x, p.y, p.z)] if r.hand_landmarks else None
                  for r in res]
        com_mao = [f for f in frames if f is not None]
        normal = [normalizar_landmarks(f) for f in com_mao]
        seq = preparar_sequencia(frames, [i * 200 for i in range(len(frames))])
        t['preparo'] = time.perf_counter() - a
        a = time.perf_counter()
        if normal:
            main.modelo.predict(normal)
        if seq is not None:
            main.modelo_gesto.prever(seq)
    else:
        maos = np.array([maos_do_resultado(r) for r in res])
        seq = preparar_frase(maos, [i * 200 for i in range(len(maos))])
        t['preparo'] = time.perf_counter() - a
        a = time.perf_counter()
        if seq is not None:
            main.modelo_frases.prever(seq)
    t['inferencia'] = time.perf_counter() - a
    t['total'] = sum(t.values())
    return t


casos = [
    ('vogais (/reconhecer_sequencia)', 'vogais', main.detector_uma_mao,
     frames_jpeg('backend/videos_frases/OLA_TUDO_BEM/referencia.mp4', 8, 5)),
    ('frases (/reconhecer_frase)', 'frases', main.detector,
     frames_jpeg('backend/videos_frases/OLA_TUDO_BEM/referencia.mp4', 25, 5)),
]

linhas = []
for nome, modo, det, imgs in casos:
    etapas(imgs, det, modo)  # aquecimento
    medidas = [etapas(imgs, det, modo) for _ in range(REPETICOES)]
    for k in medidas[0]:
        v = np.array([m[k] for m in medidas]) * 1000
        linhas.append([nome, len(imgs), k, f'{v.mean():.1f}', f'{v.std(ddof=1):.1f}'])
    tamanho = sum(len(i) for i in imgs) / 1024
    linhas.append([nome, len(imgs), 'tamanho_envio_kb_base64', f'{tamanho:.0f}', ''])

os.makedirs('relatorio_tg/medicoes', exist_ok=True)
with open('relatorio_tg/medicoes/latencia_etapas.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f, delimiter=';')
    w.writerow(['caso', 'frames', 'etapa', 'media_ms', 'desvio_ms'])
    w.writerows(linhas)
print('maquina:', platform.processor(), platform.system(), platform.release(), 'python', platform.python_version())
for l in linhas:
    print(';'.join(map(str, l)))
