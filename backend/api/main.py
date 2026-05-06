from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import pickle
import numpy as np
import base64

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

modelo_path = "backend/hand_landmarker.task"
modelo_pkl = "backend/modelo/modelo.pkl"

with open(modelo_pkl, 'rb') as f:
    modelo = pickle.load(f)

base_options = python.BaseOptions(model_asset_path=modelo_path)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1
)
detector = vision.HandLandmarker.create_from_options(options)

class ImagemRequest(BaseModel):
    imagem: str

@app.post("/reconhecer")
async def reconhecer(request: ImagemRequest):
    img_bytes = base64.b64decode(request.imagem)
    img_array = np.frombuffer(img_bytes, dtype=np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result = detector.detect(mp_image)

    if result.hand_landmarks:
        hand = result.hand_landmarks[0]
        row = []
        for landmark in hand:
            row += [landmark.x, landmark.y, landmark.z]
        predicao = modelo.predict([row])
        return {"letra": predicao[0], "detectado": True}

    return {"letra": "", "detectado": False}