from flask import Flask
import os
import socket

app = Flask(__name__)

# Configurable via environment variable
GREETING = os.environ.get("GREETING", "Hello")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "development")
# TODO: Replace "YOUR_NAME_HERE" with your actual name!
STUDENT_NAME = os.environ.get("STUDENT_NAME", "YOUR_NAME_HERE")
# TODO: Replace with your GitHub username
GITHUB_USERNAME = "YOUR_GITHUB_USERNAME"

@app.route("/")
def home():
    hostname = socket.gethostname()
    return f"""
    <html>
    <head>
        <title>Container App</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
            .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); max-width: 600px; }}
            h1 {{ color: #2196F3; }}
            .info {{ background: #e3f2fd; padding: 15px; border-radius: 5px; margin-top: 20px; }}
            .info p {{ margin: 5px 0; }}
            code {{ background: #263238; color: #80cbc4; padding: 2px 6px; border-radius: 3px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>{GREETING} from Container Land! 🐳</h1>
            <div class="info">
                <p><strong>Student:</strong> {STUDENT_NAME}</p>
                <p><strong>Environment:</strong> {ENVIRONMENT}</p>
                <p><strong>Hostname:</strong> <code>{hostname}</code></p>
                <p><strong>Python:</strong> <code>{os.sys.executable}</code></p>
            </div>
            <p style="margin-top: 20px; color: #666;">
                Try the <a href="/health">/health</a> or <a href="/student">/student</a> endpoints for JSON responses.
            </p>
        </div>
    </body>
    </html>
    """

@app.route("/health")
def health():
    return {"status": "healthy", "hostname": socket.gethostname()}

@app.route("/student")
def student():
    """Student information endpoint - REQUIRED for assignment submission"""
    return {
        "name": STUDENT_NAME,
        "github_username": GITHUB_USERNAME,
        "container_tag": "v2-student"
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting server on port {port}...")
    app.run(host="0.0.0.0", port=port)
