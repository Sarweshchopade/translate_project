"""
Model optimization script for converting models to TensorFlow Lite format
for mobile deployment in the Smart India Hackathon project
"""

import os
import torch
import numpy as np
from transformers import (
    MarianMTModel, MarianTokenizer,
    BlipProcessor, BlipForConditionalGeneration,
    WhisperProcessor, WhisperForConditionalGeneration
)
import tensorflow as tf
from tensorflow import lite
import logging
from pathlib import Path
import argparse
from typing import Dict, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelOptimizer:
    """Class for optimizing models for mobile deployment"""
    
    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def optimize_translation_model(
        self,
        model_name: str,
        source_lang: str,
        target_lang: str,
        max_length: int = 512
    ):
        """Optimize translation model for mobile deployment"""
        
        logger.info(f"Optimizing translation model: {model_name}")
        
        try:
            # Load model and tokenizer
            tokenizer = MarianTokenizer.from_pretrained(model_name)
            model = MarianMTModel.from_pretrained(model_name)
            model.eval()
            
            # Create dummy input for tracing
            dummy_text = "Hello world"
            inputs = tokenizer(
                dummy_text,
                return_tensors="pt",
                padding=True,
                truncation=True,
                max_length=max_length
            )
            
            # Trace the model
            traced_model = torch.jit.trace(model, (inputs.input_ids, inputs.attention_mask))
            
            # Save PyTorch model
            model_dir = self.output_dir / f"translation_{source_lang}_{target_lang}"
            model_dir.mkdir(exist_ok=True)
            
            traced_model.save(str(model_dir / "model.pt"))
            tokenizer.save_pretrained(str(model_dir))
            
            # Convert to ONNX for better mobile compatibility
            self._convert_to_onnx(
                model=model,
                tokenizer=tokenizer,
                output_path=model_dir / "model.onnx",
                max_length=max_length
            )
            
            # Create model metadata
            metadata = {
                "model_type": "translation",
                "source_language": source_lang,
                "target_language": target_lang,
                "max_length": max_length,
                "model_name": model_name,
                "vocab_size": tokenizer.vocab_size,
                "special_tokens": {
                    "pad_token": tokenizer.pad_token,
                    "eos_token": tokenizer.eos_token,
                    "bos_token": tokenizer.bos_token,
                    "unk_token": tokenizer.unk_token,
                }
            }
            
            with open(model_dir / "metadata.json", "w") as f:
                import json
                json.dump(metadata, f, indent=2)
            
            logger.info(f"✓ Translation model optimized: {model_dir}")
            
        except Exception as e:
            logger.error(f"Failed to optimize translation model {model_name}: {e}")
    
    def optimize_ocr_model(self, language: str, max_length: int = 100):
        """Optimize OCR model for mobile deployment"""
        
        logger.info(f"Optimizing OCR model for language: {language}")
        
        try:
            # Load BLIP model
            processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
            model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")
            model.eval()
            
            # Create dummy input for tracing
            dummy_image = torch.randn(3, 224, 224)  # RGB image
            inputs = processor(images=dummy_image, return_tensors="pt")
            
            # Trace the model
            traced_model = torch.jit.trace(model, (inputs.pixel_values,))
            
            # Save PyTorch model
            model_dir = self.output_dir / f"ocr_{language}"
            model_dir.mkdir(exist_ok=True)
            
            traced_model.save(str(model_dir / "model.pt"))
            processor.save_pretrained(str(model_dir))
            
            # Convert to ONNX
            self._convert_ocr_to_onnx(
                model=model,
                processor=processor,
                output_path=model_dir / "model.onnx"
            )
            
            # Create model metadata
            metadata = {
                "model_type": "ocr",
                "language": language,
                "max_length": max_length,
                "model_name": "Salesforce/blip-image-captioning-base",
                "image_size": 224,
                "vocab_size": processor.tokenizer.vocab_size,
            }
            
            with open(model_dir / "metadata.json", "w") as f:
                import json
                json.dump(metadata, f, indent=2)
            
            logger.info(f"✓ OCR model optimized: {model_dir}")
            
        except Exception as e:
            logger.error(f"Failed to optimize OCR model for {language}: {e}")
    
    def optimize_asr_model(self, language: str):
        """Optimize ASR model for mobile deployment"""
        
        logger.info(f"Optimizing ASR model for language: {language}")
        
        try:
            # Load Whisper model
            model_name = "openai/whisper-tiny" if language != "en" else "openai/whisper-tiny.en"
            processor = WhisperProcessor.from_pretrained(model_name)
            model = WhisperForConditionalGeneration.from_pretrained(model_name)
            model.eval()
            
            # Create dummy input for tracing
            dummy_audio = torch.randn(1, 80, 3000)  # Mel spectrogram
            inputs = processor(audio=dummy_audio, return_tensors="pt")
            
            # Trace the model
            traced_model = torch.jit.trace(model, (inputs.input_features,))
            
            # Save PyTorch model
            model_dir = self.output_dir / f"asr_{language}"
            model_dir.mkdir(exist_ok=True)
            
            traced_model.save(str(model_dir / "model.pt"))
            processor.save_pretrained(str(model_dir))
            
            # Convert to ONNX
            self._convert_asr_to_onnx(
                model=model,
                processor=processor,
                output_path=model_dir / "model.onnx"
            )
            
            # Create model metadata
            metadata = {
                "model_type": "asr",
                "language": language,
                "model_name": model_name,
                "sample_rate": 16000,
                "n_mels": 80,
                "vocab_size": processor.tokenizer.vocab_size,
            }
            
            with open(model_dir / "metadata.json", "w") as f:
                import json
                json.dump(metadata, f, indent=2)
            
            logger.info(f"✓ ASR model optimized: {model_dir}")
            
        except Exception as e:
            logger.error(f"Failed to optimize ASR model for {language}: {e}")
    
    def _convert_to_onnx(self, model, tokenizer, output_path: Path, max_length: int = 512):
        """Convert PyTorch model to ONNX format"""
        
        try:
            # Create dummy input
            dummy_text = "Hello world"
            inputs = tokenizer(
                dummy_text,
                return_tensors="pt",
                padding=True,
                truncation=True,
                max_length=max_length
            )
            
            # Export to ONNX
            torch.onnx.export(
                model,
                (inputs.input_ids, inputs.attention_mask),
                str(output_path),
                export_params=True,
                opset_version=11,
                do_constant_folding=True,
                input_names=['input_ids', 'attention_mask'],
                output_names=['logits'],
                dynamic_axes={
                    'input_ids': {0: 'batch_size', 1: 'sequence_length'},
                    'attention_mask': {0: 'batch_size', 1: 'sequence_length'},
                    'logits': {0: 'batch_size', 1: 'sequence_length'}
                }
            )
            
            logger.info(f"✓ ONNX model saved: {output_path}")
            
        except Exception as e:
            logger.error(f"Failed to convert to ONNX: {e}")
    
    def _convert_ocr_to_onnx(self, model, processor, output_path: Path):
        """Convert OCR model to ONNX format"""
        
        try:
            # Create dummy input
            dummy_image = torch.randn(1, 3, 224, 224)
            
            # Export to ONNX
            torch.onnx.export(
                model,
                dummy_image,
                str(output_path),
                export_params=True,
                opset_version=11,
                do_constant_folding=True,
                input_names=['pixel_values'],
                output_names=['logits'],
                dynamic_axes={
                    'pixel_values': {0: 'batch_size'},
                    'logits': {0: 'batch_size', 1: 'sequence_length'}
                }
            )
            
            logger.info(f"✓ OCR ONNX model saved: {output_path}")
            
        except Exception as e:
            logger.error(f"Failed to convert OCR to ONNX: {e}")
    
    def _convert_asr_to_onnx(self, model, processor, output_path: Path):
        """Convert ASR model to ONNX format"""
        
        try:
            # Create dummy input
            dummy_audio = torch.randn(1, 80, 3000)
            
            # Export to ONNX
            torch.onnx.export(
                model,
                dummy_audio,
                str(output_path),
                export_params=True,
                opset_version=11,
                do_constant_folding=True,
                input_names=['input_features'],
                output_names=['logits'],
                dynamic_axes={
                    'input_features': {0: 'batch_size', 2: 'time_frames'},
                    'logits': {0: 'batch_size', 1: 'sequence_length'}
                }
            )
            
            logger.info(f"✓ ASR ONNX model saved: {output_path}")
            
        except Exception as e:
            logger.error(f"Failed to convert ASR to ONNX: {e}")
    
    def create_model_bundle(self):
        """Create a complete model bundle for mobile deployment"""
        
        logger.info("Creating model bundle...")
        
        # Create bundle directory
        bundle_dir = self.output_dir / "mobile_bundle"
        bundle_dir.mkdir(exist_ok=True)
        
        # Copy all optimized models
        for model_dir in self.output_dir.iterdir():
            if model_dir.is_dir() and model_dir.name != "mobile_bundle":
                import shutil
                shutil.copytree(model_dir, bundle_dir / model_dir.name)
        
        # Create bundle metadata
        bundle_metadata = {
            "bundle_version": "1.0.0",
            "created_at": str(tf.timestamp()),
            "models": list(self.output_dir.glob("*/metadata.json")),
            "total_size_mb": self._get_directory_size(bundle_dir) / (1024 * 1024),
        }
        
        with open(bundle_dir / "bundle_metadata.json", "w") as f:
            import json
            json.dump(bundle_metadata, f, indent=2)
        
        logger.info(f"✓ Model bundle created: {bundle_dir}")
    
    def _get_directory_size(self, directory: Path) -> int:
        """Get total size of directory in bytes"""
        total_size = 0
        for file_path in directory.rglob("*"):
            if file_path.is_file():
                total_size += file_path.stat().st_size
        return total_size

def main():
    parser = argparse.ArgumentParser(description="Optimize models for mobile deployment")
    parser.add_argument("--output_dir", type=str, default="optimized_models", help="Output directory for optimized models")
    parser.add_argument("--optimize_translation", action="store_true", help="Optimize translation models")
    parser.add_argument("--optimize_ocr", action="store_true", help="Optimize OCR models")
    parser.add_argument("--optimize_asr", action="store_true", help="Optimize ASR models")
    parser.add_argument("--create_bundle", action="store_true", help="Create mobile model bundle")
    parser.add_argument("--languages", nargs="+", default=["en", "hi", "ne", "si", "ta", "mr"], help="Languages to optimize")
    
    args = parser.parse_args()
    
    optimizer = ModelOptimizer(args.output_dir)
    
    if args.optimize_translation:
        logger.info("Optimizing translation models...")
        
        # Define language pairs
        language_pairs = [
            ('en', 'hi'), ('hi', 'en'),
            ('en', 'ne'), ('ne', 'en'),
            ('en', 'si'), ('si', 'en'),
            ('en', 'ta'), ('ta', 'en'),
            ('en', 'mr'), ('mr', 'en'),
        ]
        
        model_configs = {
            'en-hi': 'Helsinki-NLP/opus-mt-en-hi',
            'hi-en': 'Helsinki-NLP/opus-mt-hi-en',
            'en-ne': 'Helsinki-NLP/opus-mt-en-ne',
            'ne-en': 'Helsinki-NLP/opus-mt-ne-en',
            'en-si': 'Helsinki-NLP/opus-mt-en-si',
            'si-en': 'Helsinki-NLP/opus-mt-si-en',
            'en-ta': 'Helsinki-NLP/opus-mt-en-ta',
            'ta-en': 'Helsinki-NLP/opus-mt-ta-en',
            'en-mr': 'Helsinki-NLP/opus-mt-en-mr',
            'mr-en': 'Helsinki-NLP/opus-mt-mr-en',
        }
        
        for source_lang, target_lang in language_pairs:
            pair_key = f"{source_lang}-{target_lang}"
            if pair_key in model_configs:
                optimizer.optimize_translation_model(
                    model_name=model_configs[pair_key],
                    source_lang=source_lang,
                    target_lang=target_lang
                )
    
    if args.optimize_ocr:
        logger.info("Optimizing OCR models...")
        
        for language in args.languages:
            optimizer.optimize_ocr_model(language)
    
    if args.optimize_asr:
        logger.info("Optimizing ASR models...")
        
        for language in args.languages:
            optimizer.optimize_asr_model(language)
    
    if args.create_bundle:
        logger.info("Creating mobile model bundle...")
        optimizer.create_model_bundle()
    
    logger.info("Model optimization completed!")

if __name__ == "__main__":
    main()
