#!/bin/bash
# Loopback AI Pipeline Setup Script
# Installs Whisper.cpp, Ollama, and required models

set -e

echo "🚀 Setting up Loopback AI Pipeline..."

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Whisper.cpp
echo "📦 Installing whisper.cpp..."
brew install whisper-cpp

# Install Ollama
echo "📦 Installing Ollama..."
brew install ollama

# Start Ollama service
echo "🔄 Starting Ollama service..."
brew services start ollama

# Wait for Ollama to be ready
sleep 3

# Pull required models
echo "📥 Pulling AI models..."

echo "  → llama3.1:8b (summarization)..."
ollama pull llama3.1:8b

echo "  → mistral-nemo:12b (better reasoning)..."
ollama pull mistral-nemo:12b

echo "  → nomic-embed-text (embeddings)..."
ollama pull nomic-embed-text

# Download Whisper models
echo "📥 Downloading Whisper models..."
cd /opt/homebrew/share/whisper.cpp/models 2>/dev/null || mkdir -p /opt/homebrew/share/whisper.cpp/models && cd /opt/homebrew/share/whisper.cpp/models

echo "  → ggml-large-v3.bin (best accuracy)..."
curl -L -o ggml-large-v3.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin

echo "  → ggml-medium.bin (faster)..."
curl -L -o ggml-medium.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin

# Verify installations
echo "✅ Verifying installations..."

echo "Whisper.cpp:"
which whisper-cli
whisper-cli --help | head -5

echo ""
echo "Ollama:"
ollama list

echo ""
echo "Models:"
ls -lh /opt/homebrew/share/whisper.cpp/models/

echo ""
echo "🎉 AI Pipeline setup complete!"
echo ""
echo "Next steps:"
echo "1. Add Supabase credentials to web/.env.local"
echo "2. Run: cd web && npm run dev"
echo "3. For native app: Open native/Loopback/Loopback.xcodeproj in Xcode"
echo ""
echo "Environment variables needed:"
echo "  NEXT_PUBLIC_SUPABASE_URL=your-project.supabase.co"
echo "  NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key"
echo "  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"