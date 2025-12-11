from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def hello():
    return jsonify(
        {"message": "Hello from Flask on ECS", "version": "v2", "status": "running"}
    )


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "flask-ecs-app"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
