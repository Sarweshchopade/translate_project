"""
Model training script for fine-tuning translation models
for Smart India Hackathon project
"""

import os
import json
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from transformers import (
    MarianMTModel, MarianTokenizer,
    BlipProcessor, BlipForConditionalGeneration,
    WhisperProcessor, WhisperForConditionalGeneration,
    TrainingArguments, Trainer,
    AutoTokenizer, AutoModelForSeq2SeqLM
)
from datasets import Dataset as HFDataset
import pandas as pd
from pathlib import Path
import logging
from typing import Dict, List, Tuple
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TranslationDataset(Dataset):
    """Custom dataset for translation training"""
    
    def __init__(self, source_texts: List[str], target_texts: List[str], 
                 tokenizer, max_length: int = 512):
        self.source_texts = source_texts
        self.target_texts = target_texts
        self.tokenizer = tokenizer
        self.max_length = max_length
    
    def __len__(self):
        return len(self.source_texts)
    
    def __getitem__(self, idx):
        source = self.source_texts[idx]
        target = self.target_texts[idx]
        
        # Tokenize source and target
        source_encoding = self.tokenizer(
            source, 
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        
        target_encoding = self.tokenizer(
            target,
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        
        return {
            'input_ids': source_encoding['input_ids'].squeeze(),
            'attention_mask': source_encoding['attention_mask'].squeeze(),
            'labels': target_encoding['input_ids'].squeeze()
        }

def load_translation_data(data_path: str) -> Dict[str, List[Tuple[str, str]]]:
    """Load translation datasets for different language pairs"""
    
    datasets = {}
    
    # Define language pairs
    language_pairs = [
        ('en', 'hi'), ('hi', 'en'),
        ('en', 'ne'), ('ne', 'en'),
        ('en', 'si'), ('si', 'en'),
        ('en', 'ta'), ('ta', 'en'),
        ('en', 'mr'), ('mr', 'en'),
    ]
    
    for source_lang, target_lang in language_pairs:
        pair_key = f"{source_lang}-{target_lang}"
        datasets[pair_key] = []
        
        # Load data from CSV files (you'll need to create these)
        csv_path = os.path.join(data_path, f"{pair_key}.csv")
        
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            for _, row in df.iterrows():
                datasets[pair_key].append((row['source'], row['target']))
            logger.info(f"Loaded {len(datasets[pair_key])} samples for {pair_key}")
        else:
            logger.warning(f"No data found for {pair_key} at {csv_path}")
    
    return datasets

def create_sample_data(data_path: str):
    """Create sample training data for demonstration"""
    
    os.makedirs(data_path, exist_ok=True)
    
    # Sample data for different language pairs
    sample_data = {
        'en-hi': [
            ('Hello', 'नमस्ते'),
            ('How are you?', 'आप कैसे हैं?'),
            ('Thank you', 'धन्यवाद'),
            ('Good morning', 'सुप्रभात'),
            ('Good evening', 'शुभ संध्या'),
            ('What is your name?', 'आपका नाम क्या है?'),
            ('I am fine', 'मैं ठीक हूं'),
            ('Where are you from?', 'आप कहां से हैं?'),
            ('Nice to meet you', 'आपसे मिलकर खुशी हुई'),
            ('See you later', 'बाद में मिलते हैं'),
        ],
        'hi-en': [
            ('नमस्ते', 'Hello'),
            ('आप कैसे हैं?', 'How are you?'),
            ('धन्यवाद', 'Thank you'),
            ('सुप्रभात', 'Good morning'),
            ('शुभ संध्या', 'Good evening'),
            ('आपका नाम क्या है?', 'What is your name?'),
            ('मैं ठीक हूं', 'I am fine'),
            ('आप कहां से हैं?', 'Where are you from?'),
            ('आपसे मिलकर खुशी हुई', 'Nice to meet you'),
            ('बाद में मिलते हैं', 'See you later'),
        ],
        'en-ne': [
            ('Hello', 'नमस्कार'),
            ('How are you?', 'तपाईं कसरी हुनुहुन्छ?'),
            ('Thank you', 'धन्यवाद'),
            ('Good morning', 'शुभ बिहान'),
            ('Good evening', 'शुभ साँझ'),
            ('What is your name?', 'तपाईंको नाम के हो?'),
            ('I am fine', 'म ठीक छु'),
            ('Where are you from?', 'तपाईं कहाँबाट हुनुहुन्छ?'),
            ('Nice to meet you', 'तपाईंलाई भेटेर खुसी लाग्यो'),
            ('See you later', 'पछि भेटौं'),
        ],
        'ne-en': [
            ('नमस्कार', 'Hello'),
            ('तपाईं कसरी हुनुहुन्छ?', 'How are you?'),
            ('धन्यवाद', 'Thank you'),
            ('शुभ बिहान', 'Good morning'),
            ('शुभ साँझ', 'Good evening'),
            ('तपाईंको नाम के हो?', 'What is your name?'),
            ('म ठीक छु', 'I am fine'),
            ('तपाईं कहाँबाट हुनुहुन्छ?', 'Where are you from?'),
            ('तपाईंलाई भेटेर खुसी लाग्यो', 'Nice to meet you'),
            ('पछि भेटौं', 'See you later'),
        ],
    }
    
    # Create CSV files
    for pair, data in sample_data.items():
        df = pd.DataFrame(data, columns=['source', 'target'])
        csv_path = os.path.join(data_path, f"{pair}.csv")
        df.to_csv(csv_path, index=False)
        logger.info(f"Created sample data for {pair}: {len(data)} samples")

def train_translation_model(
    model_name: str,
    source_lang: str,
    target_lang: str,
    train_data: List[Tuple[str, str]],
    output_dir: str,
    num_epochs: int = 3,
    batch_size: int = 8,
    learning_rate: float = 5e-5
):
    """Train a translation model for a specific language pair"""
    
    logger.info(f"Training {model_name} for {source_lang}-{target_lang}")
    
    # Load tokenizer and model
    tokenizer = MarianTokenizer.from_pretrained(model_name)
    model = MarianMTModel.from_pretrained(model_name)
    
    # Prepare data
    source_texts = [item[0] for item in train_data]
    target_texts = [item[1] for item in train_data]
    
    # Create dataset
    dataset = TranslationDataset(source_texts, target_texts, tokenizer)
    
    # Create HuggingFace dataset
    hf_dataset = HFDataset.from_dict({
        'input_ids': [dataset[i]['input_ids'] for i in range(len(dataset))],
        'attention_mask': [dataset[i]['attention_mask'] for i in range(len(dataset))],
        'labels': [dataset[i]['labels'] for i in range(len(dataset))]
    })
    
    # Split dataset
    train_size = int(0.8 * len(hf_dataset))
    train_dataset = hf_dataset.select(range(train_size))
    eval_dataset = hf_dataset.select(range(train_size, len(hf_dataset)))
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=num_epochs,
        per_device_train_batch_size=batch_size,
        per_device_eval_batch_size=batch_size,
        warmup_steps=100,
        weight_decay=0.01,
        logging_dir=f'{output_dir}/logs',
        logging_steps=10,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        greater_is_better=False,
    )
    
    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        tokenizer=tokenizer,
    )
    
    # Train the model
    trainer.train()
    
    # Save the model
    trainer.save_model()
    tokenizer.save_pretrained(output_dir)
    
    logger.info(f"Model saved to {output_dir}")

def train_ocr_model(
    language: str,
    train_data: List[Tuple[str, str]],  # (image_path, text)
    output_dir: str,
    num_epochs: int = 5,
    batch_size: int = 4,
    learning_rate: float = 5e-5
):
    """Train an OCR model for a specific language"""
    
    logger.info(f"Training OCR model for {language}")
    
    # Load BLIP model
    processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
    model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")
    
    # Prepare data
    image_paths = [item[0] for item in train_data]
    captions = [item[1] for item in train_data]
    
    # Create dataset
    def process_example(example):
        image = Image.open(example['image_path'])
        inputs = processor(image, return_tensors="pt")
        labels = processor.tokenizer(
            example['caption'],
            return_tensors="pt",
            padding="max_length",
            truncation=True,
            max_length=100
        )
        return {
            'pixel_values': inputs['pixel_values'].squeeze(),
            'input_ids': labels['input_ids'].squeeze(),
            'attention_mask': labels['attention_mask'].squeeze()
        }
    
    # Create HuggingFace dataset
    hf_dataset = HFDataset.from_dict({
        'image_path': image_paths,
        'caption': captions
    })
    
    # Process dataset
    processed_dataset = hf_dataset.map(process_example, remove_columns=['image_path', 'caption'])
    
    # Split dataset
    train_size = int(0.8 * len(processed_dataset))
    train_dataset = processed_dataset.select(range(train_size))
    eval_dataset = processed_dataset.select(range(train_size, len(processed_dataset)))
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=num_epochs,
        per_device_train_batch_size=batch_size,
        per_device_eval_batch_size=batch_size,
        warmup_steps=100,
        weight_decay=0.01,
        logging_dir=f'{output_dir}/logs',
        logging_steps=10,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
    )
    
    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        tokenizer=processor.tokenizer,
    )
    
    # Train the model
    trainer.train()
    
    # Save the model
    trainer.save_model()
    processor.save_pretrained(output_dir)
    
    logger.info(f"OCR model saved to {output_dir}")

def main():
    parser = argparse.ArgumentParser(description="Train translation and OCR models")
    parser.add_argument("--data_path", type=str, default="data", help="Path to training data")
    parser.add_argument("--output_path", type=str, default="models", help="Path to save trained models")
    parser.add_argument("--create_sample_data", action="store_true", help="Create sample training data")
    parser.add_argument("--train_translation", action="store_true", help="Train translation models")
    parser.add_argument("--train_ocr", action="store_true", help="Train OCR models")
    parser.add_argument("--epochs", type=int, default=3, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=8, help="Training batch size")
    
    args = parser.parse_args()
    
    # Create output directory
    os.makedirs(args.output_path, exist_ok=True)
    
    if args.create_sample_data:
        logger.info("Creating sample training data...")
        create_sample_data(args.data_path)
    
    if args.train_translation:
        logger.info("Training translation models...")
        
        # Load training data
        datasets = load_translation_data(args.data_path)
        
        # Define model configurations
        model_configs = {
            'en-hi': 'Helsinki-NLP/opus-mt-en-hi',
            'hi-en': 'Helsinki-NLP/opus-mt-hi-en',
            'en-ne': 'Helsinki-NLP/opus-mt-en-ne',
            'ne-en': 'Helsinki-NLP/opus-mt-ne-en',
        }
        
        # Train each model
        for pair_key, train_data in datasets.items():
            if pair_key in model_configs and len(train_data) > 0:
                model_name = model_configs[pair_key]
                source_lang, target_lang = pair_key.split('-')
                output_dir = os.path.join(args.output_path, f"translation_{pair_key}")
                
                train_translation_model(
                    model_name=model_name,
                    source_lang=source_lang,
                    target_lang=target_lang,
                    train_data=train_data,
                    output_dir=output_dir,
                    num_epochs=args.epochs,
                    batch_size=args.batch_size
                )
    
    if args.train_ocr:
        logger.info("Training OCR models...")
        
        # For OCR training, you would need image-text pairs
        # This is a placeholder - you'd need to implement proper OCR data loading
        languages = ['en', 'hi', 'ne', 'si', 'ta', 'mr']
        
        for lang in languages:
            # Placeholder data - replace with actual image-text pairs
            sample_data = [
                ('sample_image.jpg', f'Sample text in {lang}'),
            ]
            
            output_dir = os.path.join(args.output_path, f"ocr_{lang}")
            
            train_ocr_model(
                language=lang,
                train_data=sample_data,
                output_dir=output_dir,
                num_epochs=args.epochs,
                batch_size=args.batch_size
            )
    
    logger.info("Training completed!")

if __name__ == "__main__":
    main()
