import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import glob
import os
import sys
import numpy as np

# Transforma vídeos de frases em exemplos de treino (mesmo formato do
# coletar_frases.py). O vídeo pode ter uma ou várias repetições: cada vez
# que a pessoa levanta as mãos e depois volta ao descanso vira um exemplo.
# Os trechos de descanso viram exemplos de NENHUM.
#
# Uso: coloque os vídeos em backend/videos_frases/<FRASE>/<pessoa>.mp4
# (ou <pessoa>_<numero>.mp4 quando a mesma pessoa gravou vários) e rode
#   python backend/importar_videos.py

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from frases import FRASES, maos_do_resultado

pasta_videos = 'backend/videos_frases'
pasta_dados = 'backend/dados_frases'

ALTURA_MINIMA = 1.0     # quanto o pulso sobe acima do descanso (em tamanhos de mão)
UM_SINAL_POR_VIDEO = True  # cada vídeo tem uma repetição só: junta os pedaços achados
PAUSA_MAXIMA = 0.4      # pausas menores que isso não separam repetições (s)
SINAL_MINIMO = 0.6      # trechos menores que isso são ignorados (s)
MARGEM = 0.5            # descanso mantido antes e depois do sinal (s)
DESCANSO_MINIMO = 1.2   # trecho de descanso para virar NENHUM (s)
FPS_LEITURA = 20        # vídeos de 60 fps são lidos pulando quadros (mais rápido)

detector = vision.HandLandmarker.create_from_options(vision.HandLandmarkerOptions(
    base_options=python.BaseOptions(model_asset_path='backend/hand_landmarker.task'),
    num_hands=2))


def ler_video(caminho):
    # Guarda o resultado de cada vídeo: na próxima importação só os novos são lidos
    info = os.stat(caminho)
    cache = os.path.join(pasta_videos, '.cache',
                         os.path.relpath(caminho, pasta_videos) + f'.{info.st_size}.npz')
    if os.path.exists(cache):
        d = np.load(cache)
        return d['maos'], d['tempos'], float(d['fps'])
    maos, tempos, fps = _ler_video(caminho)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    np.savez(cache, maos=maos, tempos=tempos, fps=fps)
    return maos, tempos, fps


def _ler_video(caminho):
    cap = cv2.VideoCapture(caminho)
    fps_video = cap.get(cv2.CAP_PROP_FPS) or 30
    pulo = max(1, round(fps_video / FPS_LEITURA))
    maos = []
    n = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        n += 1
        if (n - 1) % pulo:
            continue
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        maos.append(maos_do_resultado(detector.detect(
            mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))))
    cap.release()
    maos = np.array(maos)
    fps = fps_video / pulo
    return maos, np.arange(len(maos)) * 1000.0 / fps, fps


def trechos(ativo, fps):
    """Lista de (inicio, fim) dos frames ativos, juntando pausas curtas."""
    saida = []
    i = 0
    while i < len(ativo):
        if ativo[i]:
            j = i
            while j < len(ativo) and ativo[j]:
                j += 1
            if saida and (i - saida[-1][1]) / fps < PAUSA_MAXIMA:
                saida[-1] = (saida[-1][0], j)
            else:
                saida.append((i, j))
            i = j
        else:
            i += 1
    return [(a, b) for a, b in saida if (b - a) / fps >= SINAL_MINIMO]


def salvar(frase, nome, maos, tempos):
    os.makedirs(os.path.join(pasta_dados, frase), exist_ok=True)
    caminho = os.path.join(pasta_dados, frase, f'{nome}.npz')
    np.savez(caminho, maos=maos, tempos=tempos - tempos[0])
    return caminho


total = 0
for frase in FRASES:
    for video in sorted(glob.glob(os.path.join(pasta_videos, frase, '*.*'))):
        # joao_03.mp4 -> pessoa "joao", gravação "joao-03"
        base = os.path.splitext(os.path.basename(video))[0]
        pessoa = base.split('_')[0]
        gravacao = base.replace('_', '-')
        maos, tempos, fps = ler_video(video)
        if len(maos) == 0:
            print(f'{video}: não consegui ler o vídeo')
            continue

        # Altura do pulso mais alto em cada frame (y cresce para baixo)
        y = np.nanmin(maos[:, :, 1], axis=1)
        visivel = ~np.isnan(y)
        y = np.where(visivel, y, np.inf)
        if not visivel.any():
            print(f'{video}: nenhuma mão encontrada')
            continue
        # Descanso = a posição mais baixa em que as mãos costumam ficar no vídeo
        # (mãos ao lado do corpo, de pé, ou no colo, sentado). Se as mãos ficam
        # muito tempo fora do quadro, o descanso é o fundo da imagem.
        pontos = maos.reshape(len(maos), 2, 21, 3)
        tamanho_mao = np.nanmedian(np.nanmax(
            np.linalg.norm(pontos[:, :, :, :2] - pontos[:, :, :1, :2], axis=3), axis=1)[visivel])
        descanso = np.percentile(y[visivel], 95) if visivel.mean() > 0.6 else 0.95
        # Sinal = mão mais de "uma mão" acima do descanso: vale de perto e de longe
        ativo = y < descanso - ALTURA_MINIMA * tamanho_mao

        if frase == 'NENHUM':
            partes = [(0, len(maos))]
        else:
            partes = trechos(ativo, fps)
            if UM_SINAL_POR_VIDEO and len(partes) > 1:
                partes = [(partes[0][0], partes[-1][1])]
        margem = int(MARGEM * fps)

        for n, (a, b) in enumerate(partes, start=1):
            if frase != 'NENHUM':
                # Só o começo ou só o fim do sinal não é a frase: vira NENHUM,
                # para o modelo não "completar" frases pela metade
                pedaco = int(0.2 * (b - a))
                ini, fim = max(0, a - 2 * margem), min(len(maos), b + 2 * margem)
                salvar('NENHUM', f'{pessoa}_{gravacao}_inicio_{frase}_{n:02d}', maos[ini:a + pedaco], tempos[ini:a + pedaco])
                salvar('NENHUM', f'{pessoa}_{gravacao}_final_{frase}_{n:02d}', maos[b - pedaco:fim], tempos[b - pedaco:fim])
                total += 2
            a, b = max(0, a - margem), min(len(maos), b + margem)
            salvar(frase, f'{pessoa}_{gravacao}_video_{n:02d}', maos[a:b], tempos[a:b])
            total += 1
        print(f'{frase:15s} {os.path.basename(video)}: {len(partes)} repetição(ões) '
              f'de {", ".join(f"{(b - a) / fps:.1f}s" for a, b in partes)}')

        # Descanso longo (sem sinal) também é exemplo de NENHUM
        if frase != 'NENHUM':
            parado = ~ativo
            for n, (a, b) in enumerate(trechos(parado, fps), start=1):
                a, b = a + margem // 2, b - margem // 2
                if (b - a) / fps >= DESCANSO_MINIMO:
                    salvar('NENHUM', f'{pessoa}_{gravacao}_descanso_{frase}_{n:02d}', maos[a:b], tempos[a:b])
                    total += 1

print(f'\n{total} exemplos salvos em {pasta_dados}/')
