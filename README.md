# order_delivery_demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

1. System Overview
The application consists of three main components:
    • PocketBase: A single-file backend serving as the database and API for users, products, and orders.
    • Python Robot Server: A Flask application simulating the delivery robot's states, generating PINs, and updating order statuses in PocketBase.
    • Flutter Application: The cross-platform Android/Web user interface for ordering and tracking deliveries.

2. Prerequisites
Before starting, ensure you have the following installed on your machine:
    • Python 3.x: (with pip installed) Download from python.org. Ensure it's added to your system's PATH during installation.
    • Flutter SDK: Follow the installation guide on flutter.dev. Ensure you complete the "Android setup" and "Web setup" as instructed by flutter doctor.
    • Git: (Recommended for cloning the project repository) Download from git-scm.com.
    • A Code Editors: Visual Studio, VS Code, and Android Studio

3. Backend Setup:
    • Backend Setup: PocketBase will serve your database and API.
    • Download PocketBase: Go to the official PocketBase website: https://pocketbase.io/docs/install/ Download the latest stable release for your operating system. Extract the contents of the downloaded zip file into a new, dedicated folder (e.g., C:\PocketBase_Server).
    • Start the PocketBase Server: Open a new terminal window. Navigate to the directory where you extracted PocketBase. Run the server command: Command: ./pocketbase serve Keep this terminal window open. You should see output confirming it's serving on http://127.0.0.1:8090.
    • Initial Admin Setup (if first run): Open your web browser and go to: http://127.0.0.1:8090/_/ If this is your first time running PocketBase, you'll be prompted to "Create your first superuser account." Crucially, create a dedicated admin user here. This is your main administrative account for managing PocketBase itself. Keep these credentials secure.
    • Configure Collections & Data in PocketBase Admin UI:
    Log in to the PocketBase Admin UI (http://127.0.0.1:8090/_/).

    a. products Collection:
        Click + New collection.
        Name: products (Type: Base). Click Create collection.
        Fields: Add the following fields (click + New field for each):
        name: Type text, Required: Yes.
        description: Type text, Required: No.
        price: Type number, Required: Yes, Min: 0.
        image: Type file, Required: No, Max select: 1.
        API Rules (API Rules tab):
        View rule (List/Search, Single): "" (empty string) or 1=1
        Create/Update/Delete rules: Leave empty (no access)
        Click Save changes.
        Add Sample Products: Go to the products collection, click + New record and add at least two products (e.g., "Brain", "Water" with prices and optional images).
    
    b. orders Collection:
        Click + New collection.
        Name: orders (Type: Base). Click Create collection.
        Fields: Add the following fields:
        user_id: Type relation, Required: Yes, Collection name: users, Max select: 1.
        product_id: Type relation, Required: Yes, Collection name: products, Max select: 1.
        status: Type select, Required: Yes. Values: pending, delivery_started, arrived, box_opened, delivered. Allow multiple: No.
        pin: Type text, Required: No.
        API Rules (API Rules tab):
        Create rule: @request.auth.id != ""
        View rule (List/Search, Single): @request.auth.id != ""
        Update rule: @request.auth.id != ""
        Delete rule: Leave empty (no access)
        Click Save changes.

    c. users Collection (Built-in Auth Collection):
        Go to the users collection.
        Add a Regular Test User: Click + New record, provide an email (e.g., test@example.com) and password. Check verified. This user is for logging into the Flutter app.
        Add the Robot App User: Click + New record.
        Email: (This MUST match ROBOT_USER_EMAIL in robot_server.py)
        Password: RobotSecurePass123! (This MUST match ROBOT_USER_PASSWORD in robot_server.py)
        Check verified. This user is for your Python robot server's authentication.
        Click Save changes.
4. Robot Simulation Server Setup (Python Flask)
This server simulates the robot's delivery process and communicates with PocketBase.

• Get the Project Code: Download or clone your project repository to your machine (e.g., C:\Users\YourUser\order_delivery_demo).
• Install Python Dependencies: Open a new terminal window. Navigate to your project's root directory (e.g., cd C:\Users\YourUser\order_delivery_demo). Install the required Python packages (Flask, requests): Command: pip install Flask requests
(If pip isn't found, try python -m pip install Flask requests or py -m pip install Flask requests).
• Configure robot_server.py: Open robot_server.py in your code editor. Ensure the ROBOT_USER_EMAIL and ROBOT_USER_PASSWORD match the exact credentials of the robot@bedestrian.com user you created in PocketBase.
• Run the Robot Server: In the same terminal window, run the script:
Command: python robot_server.py You should see messages confirming successful authentication with PocketBase as the robot user and that the Flask server is running on http://127.0.0.1:5000. Keep this terminal window open.

5. Flutter Application Setup (Development Mode)
To run and test the app during development.
•Get the Project Code: If you haven't already, download or clone your Flutter project to your machine.
•Install Flutter Dependencies: Open a new terminal window. Navigate to your Flutter project's root directory. Run: Command: flutter pub get
•Verify Flutter Setup: Run flutter doctor to ensure all prerequisites for Android and Web development are met. Resolve any [X] or ! marks.
• Run the Flutter App:
• In the same terminal, run the app (ensure PocketBase and Robot Server are already running):Command: flutter run. Choose your desired platform (e.g., 1 for Windows desktop, 2 for Chrome web, or an Android emulator). Test the full flow: login, order placement, and observe the status changes on the "Order In Progress" page as the robot simulation progresses.

6. Building for Production
To create deployable versions of your app.
• Android APK (for direct installation on devices):
In your Flutter project's root directory (in a terminal), run:
Command: flutter build apk --release
The generated APK file will be located at:
your_project_folder/build/app/outputs/flutter-apk/app-release.apk
•Web App (for hosting on a web server):
In your Flutter project's root directory (in a terminal), run:
Command: flutter build web --release
The generated web files will be located in:
your_project_folder/build/web (The index.html file is the entry point).