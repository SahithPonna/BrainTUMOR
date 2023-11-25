from fastapi import FastAPI, File, Form, HTTPException, UploadFile, Request
from fastapi.responses import JSONResponse
import uvicorn
import numpy as np
import tensorflow as tf
import tensorflow_addons as tfa
import cv2
import os
import csv
import datetime
import sqlite3

app = FastAPI()
model = tf.keras.models.load_model('./lib/BT_CNN_model_FINAL.h5', custom_objects={'F1Score': tfa.metrics.F1Score})
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png'}
CSV_FILE = os.path.join(UPLOAD_FOLDER, 'records.csv')

def login_user(data: dict):
    username = data.get('username')
    password = data.get('password')
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect('./assets/user_credentials.db')
        cursor = conn.cursor()

        # Check if the username exists in the 'users' table
        cursor.execute("SELECT * FROM users WHERE username=?", (username,))
        user = cursor.fetchone()

        # Close the database connection
        conn.close()

        if user is None:
            print("User does not exist.")
            return JSONResponse(content={'status_code': 428}, status_code=200)

        stored_password = user[1]  # Assuming the password is stored in the second column

        if password != stored_password:
            print("Incorrect password.")
            return JSONResponse(content={'status_code': 429}, status_code=200)

        email = user[2]  # Assuming the email is stored in the third column
        print("Login successful.")
        return JSONResponse(content={'status_code': 430, 'email': email})

    except Exception as e:
        print(f"Error during login: {e}")
        return JSONResponse(content={'status_code': 500}, status_code=500)
    
def predict_and_update_csv(image_path, username):
    ci = ['glioma', 'meningioma', 'no-tumor', 'pituitary']

    # Load the image from the given path
    image = cv2.imread(image_path)

    # Resize the image to match the expected input shape
    image = cv2.resize(image, (176, 176))

    # Normalize the image
    image = image / 255.0

    # Add an extra dimension to the image
    image = np.expand_dims(image, axis=0)

    # Predict the class probabilities of the image
    prediction = model.predict(image)

    # Get the index of the class with the highest probability
    pci = np.argmax(prediction[0])
    predicted_class = ci[pci]

    # Get the current date and time
    current_datetime = datetime.datetime.now()
    date = current_datetime.date()
    time = current_datetime.strftime("%H:%M:%S.%f")[:-4]

    # Update the CSV file with the prediction result
    with open(CSV_FILE, mode='a', newline='') as csv_file:
        fieldnames = ['username', 'date', 'time', 'result']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

        # Check if the CSV file is empty and write the header if necessary
        if os.path.getsize(CSV_FILE) == 0:
            writer.writeheader()

        writer.writerow({'username': username, 'date': date, 'time': time, 'result': predicted_class})

    return predicted_class

@app.post("/lgusr")
async def login_user_route(request: Request):
    data = await request.json()
    return login_user(data)

def allowed_file(image):
    return '.' in image.filename and image.filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.post("/upload")
async def upload_and_predict(username: str, image: UploadFile = File(...)):
    if not username or not image:
        return JSONResponse(content={'predicted_class': ''}) # Return an empty string if username or image is empty

    if not allowed_file(image):
        return JSONResponse(content={'predicted_class': ''}) # Return an empty string if the filename is not allowed

    # Validate API key
    # if not apikey or apikey != "qhLusfHmKhv47SKEoZ0dq09qV9yK8t35":
        return JSONResponse(status_code=401, content={'error': 'Invalid API key'})

    # Perform image prediction and update CSV file
    predicted_class = predict_and_update_csv(image, username)

    return JSONResponse(content={'predicted_class': predicted_class})
@app.get("/hel")
async def hello_world():
    return {"message": "API, UP!"}

if __name__ == "__main__":
    # Run the FastAPI application on port 2819
    uvicorn.run(app, host="127.0.0.1", port=2819)
