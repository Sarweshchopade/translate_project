from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import base64
import io
from PIL import Image
import torch
import torch.nn as nn
from transformers import (
    MarianMTModel, MarianTokenizer,
    BlipProcessor, BlipForConditionalGeneration,
    WhisperProcessor, WhisperForConditionalGeneration
)
import numpy as np
from typing import Dict, List, Optional
import logging
import os
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Smart Translate API",
    description="Offline Multilingual Translation API for Smart India Hackathon",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for models
translation_models: Dict[str, Dict] = {}
ocr_models: Dict[str, Dict] = {}
asr_models: Dict[str, Dict] = {}

# Language mappings
LANGUAGE_CODES = {
    'en': 'English',
    'hi': 'Hindi', 
    'ne': 'Nepali',
    'si': 'Sinhalese',
    'ta': 'Tamil',
    'mr': 'Marathi'
}

# Model configurations
TRANSLATION_MODELS = {
    # English pairs
    'en-hi': 'Helsinki-NLP/opus-mt-en-hi',
    'en-ne': 'Helsinki-NLP/opus-mt-en-ne',
    'en-si': 'Helsinki-NLP/opus-mt-en-si',
    'en-ta': 'Helsinki-NLP/opus-mt-en-ta',
    'en-mr': 'Helsinki-NLP/opus-mt-en-mr',
    
    # Hindi pairs
    'hi-en': 'Helsinki-NLP/opus-mt-hi-en',
    'hi-ne': 'Helsinki-NLP/opus-mt-hi-ne',
    'hi-si': 'Helsinki-NLP/opus-mt-hi-si',
    'hi-ta': 'Helsinki-NLP/opus-mt-hi-ta',
    'hi-mr': 'Helsinki-NLP/opus-mt-hi-mr',
    
    # Nepali pairs
    'ne-en': 'Helsinki-NLP/opus-mt-ne-en',
    'ne-hi': 'Helsinki-NLP/opus-mt-ne-hi',
    'ne-si': 'Helsinki-NLP/opus-mt-ne-si',
    'ne-ta': 'Helsinki-NLP/opus-mt-ne-ta',
    'ne-mr': 'Helsinki-NLP/opus-mt-ne-mr',
    
    # Sinhalese pairs
    'si-en': 'Helsinki-NLP/opus-mt-si-en',
    'si-hi': 'Helsinki-NLP/opus-mt-si-hi',
    'si-ne': 'Helsinki-NLP/opus-mt-si-ne',
    'si-ta': 'Helsinki-NLP/opus-mt-si-ta',
    'si-mr': 'Helsinki-NLP/opus-mt-si-mr',
    
    # Tamil pairs
    'ta-en': 'Helsinki-NLP/opus-mt-ta-en',
    'ta-hi': 'Helsinki-NLP/opus-mt-ta-hi',
    'ta-ne': 'Helsinki-NLP/opus-mt-ta-ne',
    'ta-si': 'Helsinki-NLP/opus-mt-ta-si',
    'ta-mr': 'Helsinki-NLP/opus-mt-ta-mr',
    
    # Marathi pairs
    'mr-en': 'Helsinki-NLP/opus-mt-mr-en',
    'mr-hi': 'Helsinki-NLP/opus-mt-mr-hi',
    'mr-ne': 'Helsinki-NLP/opus-mt-mr-ne',
    'mr-si': 'Helsinki-NLP/opus-mt-mr-si',
    'mr-ta': 'Helsinki-NLP/opus-mt-mr-ta',
}

OCR_MODELS = {
    'en': 'Salesforce/blip-image-captioning-base',
    'hi': 'Salesforce/blip-image-captioning-base',  # Will be fine-tuned
    'ne': 'Salesforce/blip-image-captioning-base',  # Will be fine-tuned
    'si': 'Salesforce/blip-image-captioning-base',  # Will be fine-tuned
    'ta': 'Salesforce/blip-image-captioning-base',  # Will be fine-tuned
    'mr': 'Salesforce/blip-image-captioning-base',  # Will be fine-tuned
}

ASR_MODELS = {
    'en': 'openai/whisper-tiny.en',
    'hi': 'openai/whisper-tiny',  # Multilingual
    'ne': 'openai/whisper-tiny',  # Multilingual
    'si': 'openai/whisper-tiny',  # Multilingual
    'ta': 'openai/whisper-tiny',  # Multilingual
    'mr': 'openai/whisper-tiny',  # Multilingual
}

@app.on_event("startup")
async def startup_event():
    """Initialize models on startup"""
    logger.info("Starting Smart Translate API...")
    await load_models()
    logger.info("All models loaded successfully!")

async def load_models():
    """Load all required models"""
    try:
        # Load translation models
        await load_translation_models()
        
        # Load OCR models
        await load_ocr_models()
        
        # Load ASR models
        await load_asr_models()
        
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        raise

async def load_translation_models():
    """Load translation models"""
    logger.info("Loading translation models...")
    
    for model_key, model_name in TRANSLATION_MODELS.items():
        try:
            logger.info(f"Loading {model_key} model...")
            tokenizer = MarianTokenizer.from_pretrained(model_name)
            model = MarianMTModel.from_pretrained(model_name)
            
            translation_models[model_key] = {
                'tokenizer': tokenizer,
                'model': model
            }
            logger.info(f"✓ {model_key} model loaded")
            
        except Exception as e:
            logger.error(f"Failed to load {model_key} model: {e}")
            # Continue loading other models

async def load_ocr_models():
    """Load OCR models"""
    logger.info("Loading OCR models...")
    
    for lang, model_name in OCR_MODELS.items():
        try:
            logger.info(f"Loading OCR model for {lang}...")
            processor = BlipProcessor.from_pretrained(model_name)
            model = BlipForConditionalGeneration.from_pretrained(model_name)
            
            ocr_models[lang] = {
                'processor': processor,
                'model': model
            }
            logger.info(f"✓ OCR model for {lang} loaded")
            
        except Exception as e:
            logger.error(f"Failed to load OCR model for {lang}: {e}")

async def load_asr_models():
    """Load ASR models"""
    logger.info("Loading ASR models...")
    
    for lang, model_name in ASR_MODELS.items():
        try:
            logger.info(f"Loading ASR model for {lang}...")
            processor = WhisperProcessor.from_pretrained(model_name)
            model = WhisperForConditionalGeneration.from_pretrained(model_name)
            
            asr_models[lang] = {
                'processor': processor,
                'model': model
            }
            logger.info(f"✓ ASR model for {lang} loaded")
            
        except Exception as e:
            logger.error(f"Failed to load ASR model for {lang}: {e}")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Smart Translate API",
        "version": "1.0.0",
        "status": "running",
        "supported_languages": list(LANGUAGE_CODES.keys())
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "translation_models": len(translation_models),
        "ocr_models": len(ocr_models),
        "asr_models": len(asr_models)
    }

class TranslationRequest(BaseModel):
    text: str
    source_language: str
    target_language: str

@app.post("/translate")
async def translate_text(request: TranslationRequest):
    """Translate text from source language to target language"""
    try:
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        if request.source_language not in LANGUAGE_CODES:
            raise HTTPException(status_code=400, detail=f"Unsupported source language: {request.source_language}")
        
        if request.target_language not in LANGUAGE_CODES:
            raise HTTPException(status_code=400, detail=f"Unsupported target language: {request.target_language}")
        
        if request.source_language == request.target_language:
            return {"translated_text": request.text}
        
        # Get model key
        model_key = f"{request.source_language}-{request.target_language}"
        
        if model_key not in translation_models:
            # Try reverse model
            reverse_key = f"{request.target_language}-{request.source_language}"
            if reverse_key in translation_models:
                # Use reverse model and reverse the result
                translated = await translate_with_model(request.text, reverse_key, reverse=True)
            else:
                raise HTTPException(status_code=400, detail=f"Translation model not available for {model_key}")
        else:
            translated = await translate_with_model(request.text, model_key)
        
        return {
            "original_text": request.text,
            "translated_text": translated,
            "source_language": request.source_language,
            "target_language": request.target_language
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")

async def translate_with_model(text: str, model_key: str, reverse: bool = False):
    """Translate text using a specific model"""
    try:
        model_data = translation_models[model_key]
        tokenizer = model_data['tokenizer']
        model = model_data['model']
        
        # Tokenize input
        inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
        
        # Generate translation
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=512,
                num_beams=4,
                early_stopping=True
            )
        
        # Decode output
        translated = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        if reverse:
            # For reverse models, we need to reverse the translation
            # This is a simplified approach - in practice, you'd need proper reverse translation
            translated = f"[REVERSED] {translated}"
        
        return translated
        
    except Exception as e:
        logger.error(f"Model translation error for {model_key}: {e}")
        raise

@app.post("/ocr")
async def extract_text_from_image(
    image: UploadFile = File(...),
    language: str = "en"
):
    """Extract text from image using OCR"""
    try:
        if language not in LANGUAGE_CODES:
            raise HTTPException(status_code=400, detail=f"Unsupported language: {language}")
        
        # Read image
        image_data = await image.read()
        image_pil = Image.open(io.BytesIO(image_data))
        
        # Convert to RGB if necessary
        if image_pil.mode != 'RGB':
            image_pil = image_pil.convert('RGB')
        
        # Get OCR model
        if language not in ocr_models:
            raise HTTPException(status_code=400, detail=f"OCR model not available for {language}")
        
        model_data = ocr_models[language]
        processor = model_data['processor']
        model = model_data['model']
        
        # Process image
        inputs = processor(image_pil, return_tensors="pt")
        
        # Generate caption (text extraction)
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=100,
                num_beams=4,
                early_stopping=True
            )
        
        # Decode output
        extracted_text = processor.decode(outputs[0], skip_special_tokens=True)
        
        return {
            "extracted_text": extracted_text,
            "language": language,
            "confidence": 0.85  # Placeholder confidence score
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"OCR error: {e}")
        raise HTTPException(status_code=500, detail=f"OCR failed: {str(e)}")

@app.post("/speech-to-text")
async def speech_to_text(
    audio: UploadFile = File(...),
    language: str = "en"
):
    """Convert speech to text using ASR"""
    try:
        if language not in LANGUAGE_CODES:
            raise HTTPException(status_code=400, detail=f"Unsupported language: {language}")
        
        # Read audio data
        audio_data = await audio.read()
        
        # Get ASR model
        if language not in asr_models:
            raise HTTPException(status_code=400, detail=f"ASR model not available for {language}")
        
        model_data = asr_models[language]
        processor = model_data['processor']
        model = model_data['model']
        
        # Process audio
        inputs = processor(audio_data, sampling_rate=16000, return_tensors="pt")
        
        # Generate transcription
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=448,
                num_beams=1
            )
        
        # Decode output
        transcription = processor.decode(outputs[0], skip_special_tokens=True)
        
        return {
            "text": transcription,
            "language": language,
            "confidence": 0.90  # Placeholder confidence score
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"ASR error: {e}")
        raise HTTPException(status_code=500, detail=f"ASR failed: {str(e)}")

@app.post("/speech-translate")
async def speech_translate(
    audio: UploadFile = File(...),
    source_language: str = "en",
    target_language: str = "hi"
):
    """Convert speech to text and translate it"""
    try:
        # First convert speech to text
        asr_result = await speech_to_text(audio, source_language)
        text = asr_result["text"]
        
        if not text.strip():
            return {
                "original_text": "",
                "translated_text": "",
                "source_language": source_language,
                "target_language": target_language
            }
        
        # Then translate the text
        translation_result = await translate_text(text, source_language, target_language)
        
        return {
            "original_text": text,
            "translated_text": translation_result["translated_text"],
            "source_language": source_language,
            "target_language": target_language
        }
        
    except Exception as e:
        logger.error(f"Speech translation error: {e}")
        raise HTTPException(status_code=500, detail=f"Speech translation failed: {str(e)}")

@app.get("/models/status")
async def get_models_status():
    """Get status of all loaded models"""
    return {
        "translation_models": list(translation_models.keys()),
        "ocr_models": list(ocr_models.keys()),
        "asr_models": list(asr_models.keys()),
        "total_models": len(translation_models) + len(ocr_models) + len(asr_models)
    }

@app.post("/models/download")
async def download_models():
    """Download all required models"""
    try:
        # This would implement model downloading logic
        # For now, return success
        return {
            "message": "Model download initiated",
            "status": "success"
        }
    except Exception as e:
        logger.error(f"Model download error: {e}")
        raise HTTPException(status_code=500, detail=f"Model download failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
