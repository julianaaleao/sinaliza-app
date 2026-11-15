from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from collections import Counter
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import pickle
import numpy as np
import base64
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from normalizacao import normalizar_landmarks
from gesto import ModeloGesto, GESTOS, preparar_sequencia
from frases import maos_do_resultado, preparar_frase

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    # Deixa o app (no navegador) ler o tempo de processamento
    expose_headers=["X-Tempo-Processamento-Ms"],
)

# Caminhos relativos a este arquivo: funciona rodando local ou no container
base_dir = os.path.dirname(os.path.abspath(__file__))
modelo_path = os.path.join(base_dir, "hand_landmarker.task")
modelo_pkl = os.path.join(base_dir, "modelo", "modelo.pkl")
lstm_pesos = os.path.join(base_dir, "modelo", "lstm_pesos.npz")
frases_pesos = os.path.join(base_dir, "modelo", "frases_pesos.npz")

# Probabilidade mínima para considerar que o gesto OI foi feito
LIMIAR_GESTO = 0.9
# Probabilidade mínima para aceitar uma frase
LIMIAR_FRASE = 0.7

with open(modelo_pkl, 'rb') as f:
    modelo = pickle.load(f)

modelo_gesto = ModeloGesto(lstm_pesos)

# O modelo das frases só existe depois do backend/treinar_frases.py
modelo_frases = None
classes_frases = []
if os.path.exists(frases_pesos):
    modelo_frases = ModeloGesto(frases_pesos)
    classes_frases = [str(c) for c in np.load(frases_pesos)['classes']]

base_options = python.BaseOptions(model_asset_path=modelo_path)
# Vogais e OI usam uma mão (mais rápido); as frases precisam das duas
detector_uma_mao = vision.HandLandmarker.create_from_options(
    vision.HandLandmarkerOptions(base_options=base_options, num_hands=1))
detector = vision.HandLandmarker.create_from_options(
    vision.HandLandmarkerOptions(base_options=base_options, num_hands=2))


def detectar(imagem_base64, detector=detector):
    """Imagem em base64 -> resultado do MediaPipe, ou None se a imagem for inválida."""
    img_bytes = base64.b64decode(imagem_base64)
    img_array = np.frombuffer(img_bytes, dtype=np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    if frame is None:
        return None
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    return detector.detect(mp_image)


def extrair_landmarks(imagem_base64):
    """Imagem em base64 -> 63 valores (x, y, z dos 21 pontos) ou None."""
    result = detectar(imagem_base64, detector_uma_mao)
    if result is None or not result.hand_landmarks:
        return None
    row = []
    for landmark in result.hand_landmarks[0]:
        row += [landmark.x, landmark.y, landmark.z]
    return row


@app.middleware("http")
async def medir_tempo(request, call_next):
    # Tempo de processamento no servidor, para o app separar do tempo de rede
    inicio = time.perf_counter()
    resposta = await call_next(request)
    resposta.headers["X-Tempo-Processamento-Ms"] = f"{(time.perf_counter() - inicio) * 1000:.0f}"
    return resposta


@app.get("/saude")
def saude():
    """O app chama ao abrir a câmera: acorda o servidor antes do primeiro sinal."""
    return {"ok": True, "frases": modelo_frases is not None}


class ImagemRequest(BaseModel):
    imagem: str


class SequenciaRequest(BaseModel):
    imagens: List[str]
    tempos_ms: Optional[List[float]] = None


@app.post("/reconhecer")
def reconhecer(request: ImagemRequest):
    row = extrair_landmarks(request.imagem)
    if row is not None:
        predicao = modelo.predict([normalizar_landmarks(row)])
        return {"letra": predicao[0], "detectado": True}

    return {"letra": "", "detectado": False}


@app.post("/reconhecer_sequencia")
def reconhecer_sequencia(request: SequenciaRequest):
    """Recebe alguns frames seguidos (~1,5s de vídeo) e devolve:
    - gesto: "OI" se o LSTM reconheceu o gesto dinâmico
    - letra: vogal mais votada entre os frames com mão
    - resultado: o que o app deve mostrar (gesto tem prioridade)
    """
    frames = [extrair_landmarks(img) for img in request.imagens]
    com_mao = [f for f in frames if f is not None]

    if not com_mao:
        return {"resultado": "", "gesto": "", "letra": "",
                "confianca": 0.0, "detectado": False}

    gesto = ""
    confianca = 0.0
    tempos = request.tempos_ms
    if tempos is None or len(tempos) != len(frames):
        tempos = None
    sequencia = preparar_sequencia(frames, tempos)
    if sequencia is not None:
        probs = modelo_gesto.prever(sequencia)
        idx = int(np.argmax(probs))
        confianca = float(probs[idx])
        if GESTOS[idx] != 'NENHUM' and confianca >= LIMIAR_GESTO:
            gesto = GESTOS[idx]

    votos = modelo.predict([normalizar_landmarks(f) for f in com_mao])
    letra = Counter(votos).most_common(1)[0][0]

    return {
        "resultado": gesto or letra,
        "gesto": gesto,
        "letra": letra,
        "confianca": confianca,
        "detectado": True,
    }


def extrair_maos(imagem_base64):
    """Imagem em base64 -> array (2, 63) com as duas mãos (NaN onde não tem)."""
    result = detectar(imagem_base64)
    if result is None:
        return np.full((2, 63), np.nan)
    return maos_do_resultado(result)


@app.post("/reconhecer_frase")
def reconhecer_frase(request: SequenciaRequest):
    """Recebe os frames de ~3s de vídeo e devolve qual frase foi sinalizada.
    frase vem vazia quando não reconheceu nenhuma com segurança."""
    if modelo_frases is None:
        raise HTTPException(503, "Modelo de frases ainda não foi treinado")

    maos = np.array([extrair_maos(img) for img in request.imagens])
    visiveis = float((~np.isnan(maos[:, :, 0])).any(axis=1).mean()) if len(maos) else 0.0

    tempos = request.tempos_ms
    if tempos is None or len(tempos) != len(maos):
        tempos = None
    entrada = preparar_frase(maos, tempos) if len(maos) else None
    if entrada is None:
        return {"frase": "", "confianca": 0.0, "detectado": False,
                "maos_visiveis": visiveis}

    probs = modelo_frases.prever(entrada)
    idx = int(np.argmax(probs))
    frase = classes_frases[idx]
    confianca = float(probs[idx])
    if frase == 'NENHUM' or confianca < LIMIAR_FRASE:
        frase = ""

    return {"frase": frase, "confianca": confianca, "detectado": True,
            "maos_visiveis": visiveis}
