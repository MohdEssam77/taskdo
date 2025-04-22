# taskdo
## Introduction  
Welcome to the PCC coding task! Your task is to build a simple **Todo Management App** called **taskdo** using **Flutter** for the frontend and **FastAPI** for the backend. The app should support both desktop and mobile layouts while maintaining a responsive design.  

## Core Requirements  
- **Frontend**: Flutter with **flutter_bloc** for state management.  
- **Backend**: FastAPI with any database of your choice.  
- **Deployment**: Docker for containerization.  
- **Functionality**: CRUD operations for todos, including:  
  - Title  
  - Description  
  - Due date  

## Expectations  
- The app should run on **desktop** but also be **adaptable to mobile screens**.  
- The backend should expose a **REST API** that the Flutter app interacts with.  
- The project should be containerized using **Docker** for easy setup.  
- Additional features (e.g., filtering, etc.) are welcome and encouraged!

Please fork this repository and add a PR once you're done :)



For running it 
1)open docker desktop and in the terminal run
docker-compose up --build
2)Then once it is done in the browser open the following link 
http://localhost:8080