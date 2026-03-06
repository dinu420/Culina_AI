# Culina AI – Intelligent Cooking Assistant

Culina AI is an AI-powered mobile application that helps users generate recipes based on available ingredients. The system integrates computer vision, machine learning and generative AI to detect ingredients from images and automatically generate personalized cooking recipes.

The application aims to reduce food waste, improve meal planning and provide intelligent cooking assistance through a simple and user-friendly mobile interface.

---

## Key Features

- Image-based ingredient detection using a custom trained AI model
- AI-generated recipes based on detected ingredients
- Recipe refinement based on user preferences
- Cross-platform mobile application (Android & iOS)
- Intelligent cooking assistance and automation
- Support for multiple cuisines including Sri Lankan recipes

---

## System Architecture

The Culina AI system integrates multiple technologies to provide intelligent functionality.

1. **Mobile Application (Flutter)**  
   Handles user interaction, image capture and communication with AI services.

2. **Ingredient Recognition Model (TensorFlow Lite)**  
   A custom 15-class image recognition model used to identify ingredients from captured images.

3. **Cloud AI Services**  
   Used to generate cooking recipes through natural language generation.

4. **Firebase Functions (Node.js)**  
   Serverless backend that connects the mobile application with AI APIs.

---

## Technology Stack

### Mobile Application
- Flutter
- Dart

### Artificial Intelligence
- Python
- TensorFlow
- TensorFlow Lite
- Computer Vision (CNN)

### Backend
- Firebase Functions
- Node.js
- REST APIs

### Development Tools
- Visual Studio Code
- Android Studio
- Git & GitHub

---

## AI Model

The ingredient detection model was developed using deep learning techniques and trained on a dataset containing multiple vegetable classes.

Model characteristics:

- 15 ingredient classes
- Convolutional Neural Network architecture
- TensorFlow Lite optimized for mobile deployment
- Image classification based ingredient recognition

Example ingredient classes:

- Bean
- Bitter Gourd
- Bottle Gourd
- Brinjal
- Broccoli
- Cabbage
- Capsicum
- Carrot
- Cauliflower
- Cucumber
- Papaya
- Potato
- Pumpkin
- Radish
- Tomato

---


---

## How the System Works

1. The user captures an image of available ingredients.
2. The image is processed using the custom ingredient recognition model.
3. Detected ingredients are sent to the recipe generation service.
4. AI generates a complete cooking recipe.
5. Users can refine the recipe according to their preferences.

---

## Installation and Setup

### Clone the repository

git clone https://github.com/dinu420/Culina_AI.git

### Navigate to the project folder

cd Culina_ai

### Install dependencies

flutter pub get

### Run the application

flutter run


---

## Future Improvements

- Improved ingredient recognition accuracy
- Additional ingredient classes
- Recipe saving functionality
- Nutritional analysis for recipes
- Smart meal planning features

---

## Author

**Thivina Dinujaya**  
BSc (Hons) Software Engineering  

Final Year Project – Intelligent Cooking Assistant using Artificial Intelligence and Vision

---

## License

This project is developed for academic and research purposes.
