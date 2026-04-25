import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import urllib.request
import os

modelo_path = "backend/hand_landmarker.task"

if not os.path.exists(modelo_path):
    print("Baixando modelo...")
    urllib.request.urlretrieve(
        "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task",
        modelo_path
    )
    print("Modelo baixado!")

base_options = python.BaseOptions(model_asset_path=modelo_path)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1
)
detector = vision.HandLandmarker.create_from_options(options)

cap = cv2.VideoCapture(0)
print("Pressione Q para sair")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result = detector.detect(mp_image)

    if result.hand_landmarks:
        for hand in result.hand_landmarks:
            for landmark in hand:
                h, w, _ = frame.shape
                cx, cy = int(landmark.x * w), int(landmark.y * h)
                cv2.circle(frame, (cx, cy), 5, (0, 255, 0), -1)

            # Desenhar conexoes
            connections = mp.tasks.vision.HandLandmarksConnections.HAND_CONNECTIONS
            for connection in connections:
                start = hand[connection.start]
                end = hand[connection.end]
                h, w, _ = frame.shape
                x1, y1 = int(start.x * w), int(start.y * h)
                x2, y2 = int(end.x * w), int(end.y * h)
                cv2.line(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

    cv2.imshow('SINALIZA - Landmarks', frame)

    if cv2.waitKey(5) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()