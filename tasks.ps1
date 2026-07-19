param(
    [Parameter(Position = 0)]
    [string]$Task = "help",

    [string]$CondaEnv = "langgraph",
    [string]$ApiHost = "127.0.0.1",
    [string]$ApiPort = "8080",
    [string]$FlutterDevice = "chrome",
    [string]$WebHost = "127.0.0.1",
    [string]$WebPort = "5260",
    [string]$ChromeUserDataDir = "",
    [switch]$Cors,
    [ValidateSet("ollama", "gemini", "backend")]
    [string]$AiProvider = "ollama",
    [string]$BackendBaseUrl = "",
    [string]$EHospitalBaseUrl = "https://aetab8pjmb.us-east-1.awsapprunner.com",
    [string]$EHospitalAuthBaseUrl = "https://tysnx3mi2s.us-east-1.awsapprunner.com",
    [string]$OllamaBaseUrl = "http://127.0.0.1:11434",
    [string]$OllamaModel = "llama3.1:8b",
    [string]$GeminiModel = "gemini-1.5-flash",
    [string]$GeminiApiKey = "",
    [string]$FitbitClientId = "",
    [string]$FitbitClientSecret = ""
)

$ErrorActionPreference = "Stop"

function Run-Python {
    conda run -n $CondaEnv python @args
}

function Run-Uvicorn {
    $env:BACKEND_HOST = $ApiHost
    $env:BACKEND_PORT = $ApiPort
    $env:EHOSPITAL_BASE_URL = $EHospitalBaseUrl
    $env:EHOSPITAL_AUTH_BASE_URL = $EHospitalAuthBaseUrl
    $env:OLLAMA_BASE_URL = $OllamaBaseUrl
    $env:OLLAMA_MODEL = $OllamaModel
    $env:AI_MODEL_NAME = $OllamaModel
    Write-Host "Starting Smart Health backend: http://$ApiHost`:$ApiPort"
    Write-Host "Uvicorn app: src.backend.main:app"
    Write-Host "Conda env: $CondaEnv"
    conda run -n $CondaEnv --no-capture-output uvicorn @args
}

function Get-BackendBaseUrl {
    if ([string]::IsNullOrWhiteSpace($BackendBaseUrl)) {
        return "http://$ApiHost`:$ApiPort"
    }
    return $BackendBaseUrl
}

function Get-FlutterDefines {
    $effectiveBackendBaseUrl = Get-BackendBaseUrl
    @(
        "--dart-define=AI_PROVIDER=$AiProvider",
        "--dart-define=BACKEND_BASE_URL=$effectiveBackendBaseUrl",
        "--dart-define=EHOSPITAL_BASE_URL=$EHospitalBaseUrl",
        "--dart-define=OLLAMA_BASE_URL=$OllamaBaseUrl",
        "--dart-define=OLLAMA_MODEL=$OllamaModel",
        "--dart-define=GEMINI_MODEL=$GeminiModel",
        "--dart-define=GEMINI_API_KEY=$GeminiApiKey",
        "--dart-define=FITBIT_CLIENT_ID=$FitbitClientId",
        "--dart-define=FITBIT_CLIENT_SECRET=$FitbitClientSecret"
    )
}

function Run-Flutter {
    Push-Location src/app
    try { flutter @args } finally { Pop-Location }
}

function Get-CorsDisabledChromeFlags {
    $profileDir = $ChromeUserDataDir
    if ([string]::IsNullOrWhiteSpace($profileDir)) {
        $profileDir = Join-Path (Resolve-Path "src/app") ".dart_tool\chrome-cors-profile"
    }
    @(
        "--web-browser-flag=--disable-web-security",
        "--web-browser-flag=--user-data-dir=$profileDir"
    )
}

switch ($Task) {
    "help" {
        "Available tasks:"
        "  .\tasks.ps1 api                         Run Python backend on 127.0.0.1:8080"
        "  .\tasks.ps1 api-dev                     Run Python backend with reload"
        "  .\tasks.ps1 flutter-run                 Run Flutter app/device"
        "  .\tasks.ps1 flutter-web                 Run Flutter web-server"
        "  .\tasks.ps1 flutter-get                 Install Flutter dependencies"
        "  .\tasks.ps1 py-check                    Compile Python entrypoints"
        "  .\tasks.ps1 api-check                   Smoke-test remote login endpoint"
        "  .\tasks.ps1 chat-check                  Smoke-test agent chat"
        "  .\tasks.ps1 text-check                  Scan source for known mojibake markers"
        "  .\tasks.ps1 ocr-check                   Verify report interpreter OCR/PDF dependencies"
        "  .\tasks.ps1 flutter-analyze             Analyze Flutter app"
        "  .\tasks.ps1 flutter-test                Run Flutter tests"
        "  .\tasks.ps1 test                        Run Python and Flutter checks"
        ""
        "Recommended local web flow:"
        "  Terminal 1: .\tasks.ps1 api-dev"
        "  Terminal 2: .\tasks.ps1 flutter-run -AiProvider backend -Cors"
        ""
        "Use .\tasks.ps1 flutter-web -AiProvider backend if your browser does not need direct eHospital CORS bypass."
        ""
        "Useful options:"
        "  -ApiHost 127.0.0.1 -ApiPort 8080"
        "  -FlutterDevice chrome|edge|windows"
        "  -WebHost 127.0.0.1 -WebPort 5260"
        "  -AiProvider ollama|gemini|backend"
        "  -BackendBaseUrl http://127.0.0.1:8080"
        "  -EHospitalAuthBaseUrl http://127.0.0.1:8081"
        "  -ChromeUserDataDir <path>"
        "  -Cors"
    }
    "api" {
        Run-Uvicorn src.backend.main:app --host $ApiHost --port $ApiPort --log-level info --access-log
    }
    "api-dev" {
        Run-Uvicorn src.backend.main:app --reload --host $ApiHost --port $ApiPort --log-level info --access-log
    }
    "py-check" {
        Run-Python -m py_compile src/demo/demo2.py src/backend/main.py
    }
    "api-check" {
        $env:MODEL_PROVIDER = "ollama"
        $env:MODEL_NAME = $OllamaModel
        Run-Python -c "from fastapi.testclient import TestClient; import src.backend.api.demo as demo; exec(\"async def fake(email, password, selected_option):\n    return {'patient_id': 20, 'user_id': 20, 'email': email, 'username': 'Test Patient', 'selectedOption': selected_option}\"); demo.authenticate_ehospital_user=fake; from src.backend.main import app; c=TestClient(app); assert c.post('/login', json={'email':'patient@example.com','password':'secret','selectedOption':'Patient'}).json()['patient_id'] == 20; assert c.post('/login', json={'username':'john','password':'john123'}).status_code == 422; print('api ok')"
    }
    "chat-check" {
        Run-Python -c "from src.demo.demo2 import run_chat_for_user; print(run_chat_for_user('u_001', 'What is my weight, average sleep, and primary workout type?'))"
    }
    "text-check" {
        $markerCodes = @(0x8DEF, 0x922B, 0x9239, 0x923A, 0x9241, 0x5364, 0x63B3, 0x922E, 0x00C3, 0x00C2)
        $pattern = ($markerCodes | ForEach-Object { [regex]::Escape([string][char]$_) }) -join "|"
        & rg -n $pattern src/app/lib src/backend
        if ($LASTEXITCODE -eq 0) {
            throw "Known mojibake markers found."
        }
        if ($LASTEXITCODE -gt 1) {
            throw "Text hygiene scan failed."
        }
        "text ok"
    }
    "ocr-check" {
        Run-Python -c "import importlib.util, shutil, sys; packages={'multipart':'python-multipart','pypdf':'pypdf','pdf2image':'pdf2image','PIL':'pillow','pytesseract':'pytesseract'}; missing=[label for module,label in packages.items() if importlib.util.find_spec(module) is None]; tools=[tool for tool in ('tesseract','pdfinfo','pdftoppm') if shutil.which(tool) is None]; print('missing python packages:', missing or 'none'); print('missing system tools:', tools or 'none'); sys.exit(1 if missing or tools else 0)"
    }
    "flutter-get" {
        Run-Flutter pub get
    }
    "flutter-analyze" {
        Run-Flutter analyze
    }
    "flutter-test" {
        Run-Flutter test @("--dart-define=AI_PROVIDER=$AiProvider", "--dart-define=GEMINI_API_KEY=$GeminiApiKey")
    }
    "flutter-run" {
        $defines = Get-FlutterDefines
        if ($Cors) {
            $flags = Get-CorsDisabledChromeFlags
            Run-Flutter run -d chrome @flags @defines
        } else {
            Run-Flutter run -d $FlutterDevice @defines
        }
    }
    "flutter-web" {
        $defines = Get-FlutterDefines
        Run-Flutter run -d web-server --web-hostname $WebHost --web-port $WebPort @defines
    }
    "test" {
        & $PSCommandPath py-check -CondaEnv $CondaEnv
        & $PSCommandPath api-check -CondaEnv $CondaEnv
        & $PSCommandPath text-check -CondaEnv $CondaEnv
        & $PSCommandPath flutter-analyze -CondaEnv $CondaEnv
        & $PSCommandPath flutter-test -CondaEnv $CondaEnv
    }
    default {
        throw "Unknown task '$Task'. Run .\tasks.ps1 help"
    }
}
