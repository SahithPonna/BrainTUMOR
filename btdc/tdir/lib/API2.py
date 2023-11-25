from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
import tensorflow_addons as tfa
import cv2
import os
import csv
import datetime

app = Flask(__name__)
model = tf.keras.models.load_model('./lib/BT_CNN_model_FINAL.h5', custom_objects={'F1Score': tfa.metrics.F1Score})

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png'}
CSV_FILE = os.path.join(UPLOAD_FOLDER, 'records.csv')  # Path to the CSV file

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Define a dictionary to store active API keys
free_api_keys = {"qhLusfHmKhv47SKEoZ0dq09qV9yK8t35"}

# Define a set to store active premium API keys
premium_api_keys = set()

# Function to read premium API keys from the CSV file
def load_premium_api_keys():
    with open('./lib/premium_api_keys.csv', mode='r') as csv_file:
        csv_reader = csv.reader(csv_file)
        for row in csv_reader:
            if row:
                premium_api_keys.add(row[0])

# Load premium API keys from the CSV file
load_premium_api_keys()

def get_history_records(username):
    records = []
    with open(CSV_FILE, mode='r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        for row in csv_reader:
            if row['username'] == username:
                records.append({
                    'date': row['date'],
                    'time': row['time'],
                    'result': row['result']
                })
    return records

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Function to count the number of images in a user's folder
def count_images_in_folder(username):
    user_folder = os.path.join(app.config['UPLOAD_FOLDER'], username)
    if os.path.exists(user_folder):
        return len([f for f in os.listdir(user_folder) if os.path.isfile(os.path.join(user_folder, f))])
    return 0

# Function to predict the image and update the CSV file
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

@app.route("/history", methods=['GET'])
def get_user_history():
    username = request.args.get('username')  # Get the username from the query parameter

    # Fetch history records for the username
    records = get_history_records(username)
    if not records:
        return ('', 204)

    return jsonify(records)

@app.route("/upload", methods=['POST'])
def upload_and_predict():
    api_key = request.headers.get('Authorization')  # Get the API key from the request headers
    username = request.form.get('username')  # Get the username from the request

    # Check if the API key is valid and active
    if api_key not in free_api_keys and api_key not in premium_api_keys:
        return '', 238  # Return status code 238 as an error for an invalid or inactive key

    if 'image' not in request.files:
        return jsonify({'predicted_class': ''})  # Return an empty string if no file part

    file = request.files['image']

    if file.filename == '' or username is None:
        return jsonify({'predicted_class': ''})  # Return an empty string if no selected file or username

    # Check if the user has already uploaded a maximum number of images
    if (api_key in free_api_keys and count_images_in_folder(username) >= 5):
        return '', 273  # Return status code 283 as an error
    elif(api_key in premium_api_keys and count_images_in_folder(username) >= 15):
        return '', 283

    if file and allowed_file(file.filename):
        user_upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], username)
        if not os.path.exists(user_upload_folder):
            os.makedirs(user_upload_folder)  # Create a subfolder based on the username if it doesn't exist

        filename = os.path.join(user_upload_folder, file.filename)
        file.save(filename)

        # Perform the image prediction and update the CSV file
        predicted_class = predict_and_update_csv(filename, username)

        return jsonify(predicted_class)

    return jsonify({'predicted_class': ''})  # Return an empty string for an invalid file format

if __name__ == "__main__":
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    app.run(host='0.0.0.0', port=2819)
