CONDA_ENV ?= langgraph
CONDA_RUN := conda run --no-capture-output -n $(CONDA_ENV)
PYTHON := $(CONDA_RUN) python
UVICORN := $(CONDA_RUN) uvicorn
FLUTTER := flutter
API_HOST ?= 127.0.0.1
API_PORT ?= 8080
APP_DIR := src/app
FLUTTER_DEVICE ?= chrome
WEB_HOST ?= 127.0.0.1
WEB_PORT ?= 5260
CHROME_USER_DATA_DIR ?= .dart_tool/chrome-cors-profile
CORS ?= 0
AI_PROVIDER ?= ollama
BACKEND_BASE_URL ?= http://$(API_HOST):$(API_PORT)
EHOSPITAL_BASE_URL ?= https://aetab8pjmb.us-east-1.awsapprunner.com
EHOSPITAL_AUTH_BASE_URL ?= https://tysnx3mi2s.us-east-1.awsapprunner.com
OLLAMA_BASE_URL ?= http://127.0.0.1:11434
OLLAMA_MODEL ?= gemma3:4b
GEMINI_MODEL ?= gemini-1.5-flash
GEMINI_API_KEY ?=
FITBIT_CLIENT_ID ?=
FITBIT_CLIENT_SECRET ?=

FLUTTER_COMMON_DEFINES := --dart-define=BACKEND_BASE_URL=$(BACKEND_BASE_URL) --dart-define=EHOSPITAL_BASE_URL=$(EHOSPITAL_BASE_URL) --dart-define=OLLAMA_BASE_URL=$(OLLAMA_BASE_URL) --dart-define=OLLAMA_MODEL=$(OLLAMA_MODEL) --dart-define=GEMINI_MODEL=$(GEMINI_MODEL) --dart-define=GEMINI_API_KEY=$(GEMINI_API_KEY) --dart-define=FITBIT_CLIENT_ID=$(FITBIT_CLIENT_ID) --dart-define=FITBIT_CLIENT_SECRET=$(FITBIT_CLIENT_SECRET)
FLUTTER_DEFINES := --dart-define=AI_PROVIDER=$(AI_PROVIDER) $(FLUTTER_COMMON_DEFINES)
BACKEND_ENV := PYTHONUNBUFFERED=1 BACKEND_HOST=$(API_HOST) BACKEND_PORT=$(API_PORT) EHOSPITAL_BASE_URL=$(EHOSPITAL_BASE_URL) EHOSPITAL_AUTH_BASE_URL=$(EHOSPITAL_AUTH_BASE_URL) OLLAMA_BASE_URL=$(OLLAMA_BASE_URL) OLLAMA_MODEL=$(OLLAMA_MODEL) AI_MODEL_PROVIDER=ollama AI_MODEL_NAME=$(OLLAMA_MODEL) MODEL_PROVIDER=ollama MODEL_NAME=$(OLLAMA_MODEL)
FLUTTER_RUN_DEVICE := $(if $(filter 1 true yes,$(CORS)),chrome,$(FLUTTER_DEVICE))
FLUTTER_CORS_FLAGS := $(if $(filter 1 true yes,$(CORS)),--web-browser-flag=--disable-web-security --web-browser-flag=--user-data-dir=$(CHROME_USER_DATA_DIR),)

.PHONY: help api api-dev py-check api-check text-check ocr-check flutter-get flutter-analyze flutter-test flutter-run flutter-web test

help:
	@echo "Available targets:"
	@echo "  make api             Run Python backend on $(API_HOST):$(API_PORT)"
	@echo "  make api-dev         Run Python backend with reload"
	@echo "  make flutter-run     Run Flutter app/device"
	@echo "  make flutter-web     Run Flutter web-server"
	@echo "  make flutter-get     Install Flutter dependencies"
	@echo "  make py-check        Compile Python entrypoints"
	@echo "  make api-check       Smoke-test remote login endpoint"
	@echo "  make text-check      Scan source for known mojibake markers"
	@echo "  make ocr-check       Verify report interpreter OCR/PDF dependencies"
	@echo "  make flutter-analyze Analyze Flutter app"
	@echo "  make flutter-test    Run Flutter tests"
	@echo "  make test            Run Python and Flutter checks"
	@echo ""
	@echo "Recommended local web flow:"
	@echo "  Terminal 1: make api-dev"
	@echo "  Terminal 2: make flutter-run AI_PROVIDER=backend CORS=1"
	@echo ""
	@echo "Use make flutter-web AI_PROVIDER=backend if your browser does not need direct eHospital CORS bypass."

api:
	$(BACKEND_ENV) $(UVICORN) src.backend.main:app --host $(API_HOST) --port $(API_PORT) --log-level info --access-log

api-dev:
	$(BACKEND_ENV) $(UVICORN) src.backend.main:app --reload --host $(API_HOST) --port $(API_PORT) --log-level info --access-log

py-check:
	$(PYTHON) -m py_compile src/backend/main.py src/backend/api/auth.py

api-check:
	MODEL_PROVIDER=ollama MODEL_NAME=$(OLLAMA_MODEL) $(PYTHON) -c "from fastapi.testclient import TestClient; import src.backend.api.auth as auth; exec(\"async def fake(email, password, selected_option):\\n    return {'patient_id': 20, 'user_id': 20, 'email': email, 'username': 'Test Patient', 'selectedOption': selected_option}\"); auth.authenticate_ehospital_user=fake; from src.backend.main import app; c=TestClient(app); assert c.post('/login', json={'email':'patient@example.com','password':'secret','selectedOption':'Patient'}).json()['patient_id'] == 20; assert c.post('/login', json={'username':'john','password':'john123'}).status_code == 422; print('api ok')"

text-check:
	@powershell -NoProfile -ExecutionPolicy Bypass -File tasks.ps1 text-check

ocr-check:
	$(PYTHON) -c "import importlib.util, shutil, sys; packages={'multipart':'python-multipart','pypdf':'pypdf','pdf2image':'pdf2image','PIL':'pillow','pytesseract':'pytesseract'}; missing=[label for module,label in packages.items() if importlib.util.find_spec(module) is None]; tools=[tool for tool in ('tesseract','pdfinfo','pdftoppm') if shutil.which(tool) is None]; print('missing python packages:', missing or 'none'); print('missing system tools:', tools or 'none'); sys.exit(1 if missing or tools else 0)"

flutter-get:
	cd $(APP_DIR) && $(FLUTTER) pub get

flutter-analyze:
	cd $(APP_DIR) && $(FLUTTER) analyze

flutter-test:
	cd $(APP_DIR) && $(FLUTTER) test --dart-define=AI_PROVIDER=$(AI_PROVIDER) --dart-define=GEMINI_API_KEY=$(GEMINI_API_KEY)

flutter-run:
	cd $(APP_DIR) && $(FLUTTER) run -d $(FLUTTER_RUN_DEVICE) $(FLUTTER_CORS_FLAGS) $(FLUTTER_DEFINES)

flutter-web:
	cd $(APP_DIR) && $(FLUTTER) run -d web-server --web-hostname $(WEB_HOST) --web-port $(WEB_PORT) $(FLUTTER_DEFINES)

test: py-check api-check text-check flutter-analyze flutter-test
