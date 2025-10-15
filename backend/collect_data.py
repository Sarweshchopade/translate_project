"""
Data collection script for gathering training data
for the Smart India Hackathon translation project
"""

import os
import json
import requests
import pandas as pd
from pathlib import Path
import logging
from typing import Dict, List, Tuple
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import random

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataCollector:
    """Class for collecting translation training data"""
    
    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Common phrases for translation
        self.common_phrases = {
            'en': [
                "Hello", "How are you?", "Thank you", "Good morning", "Good evening",
                "What is your name?", "I am fine", "Where are you from?", "Nice to meet you",
                "See you later", "Goodbye", "Please", "Excuse me", "I'm sorry",
                "Yes", "No", "Maybe", "I don't know", "I understand", "I don't understand",
                "Can you help me?", "How much does this cost?", "Where is the bathroom?",
                "I need help", "Call the police", "I'm lost", "I'm hungry", "I'm thirsty",
                "What time is it?", "Today", "Tomorrow", "Yesterday", "Now", "Later",
                "Here", "There", "This", "That", "Big", "Small", "Good", "Bad",
                "Hot", "Cold", "Fast", "Slow", "New", "Old", "Beautiful", "Ugly",
                "Happy", "Sad", "Angry", "Tired", "Sick", "Healthy", "Rich", "Poor",
                "Work", "Home", "School", "Hospital", "Restaurant", "Hotel", "Airport",
                "Train station", "Bus stop", "Market", "Bank", "Post office", "Library",
                "Park", "Beach", "Mountain", "River", "City", "Village", "Country",
                "Family", "Mother", "Father", "Brother", "Sister", "Son", "Daughter",
                "Friend", "Neighbor", "Teacher", "Doctor", "Engineer", "Student",
                "Food", "Water", "Milk", "Bread", "Rice", "Meat", "Fish", "Vegetables",
                "Fruits", "Coffee", "Tea", "Beer", "Wine", "Breakfast", "Lunch", "Dinner",
                "Money", "Price", "Cheap", "Expensive", "Buy", "Sell", "Pay", "Change",
                "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
                "Red", "Blue", "Green", "Yellow", "Black", "White", "Orange", "Purple",
                "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            ]
        }
        
        # Language-specific phrases
        self.language_phrases = {
            'hi': [
                "नमस्ते", "आप कैसे हैं?", "धन्यवाद", "सुप्रभात", "शुभ संध्या",
                "आपका नाम क्या है?", "मैं ठीक हूं", "आप कहां से हैं?", "आपसे मिलकर खुशी हुई",
                "बाद में मिलते हैं", "अलविदा", "कृपया", "माफ करें", "मुझे माफ करें",
                "हां", "नहीं", "शायद", "मुझे नहीं पता", "मैं समझता हूं", "मैं नहीं समझता",
                "क्या आप मेरी मदद कर सकते हैं?", "इसकी कीमत कितनी है?", "शौचालय कहां है?",
                "मुझे मदद चाहिए", "पुलिस को बुलाएं", "मैं खो गया हूं", "मुझे भूख लगी है", "मुझे प्यास लगी है"
            ],
            'ne': [
                "नमस्कार", "तपाईं कसरी हुनुहुन्छ?", "धन्यवाद", "शुभ बिहान", "शुभ साँझ",
                "तपाईंको नाम के हो?", "म ठीक छु", "तपाईं कहाँबाट हुनुहुन्छ?", "तपाईंलाई भेटेर खुसी लाग्यो",
                "पछि भेटौं", "अलविदा", "कृपया", "माफ गर्नुहोस्", "मलाई माफ गर्नुहोस्",
                "हो", "होइन", "हुनसक्छ", "मलाई थाहा छैन", "म बुझ्छु", "म बुझ्दिन",
                "के तपाईंले मेरो मद्दत गर्न सक्नुहुन्छ?", "यसको मूल्य कति हो?", "शौचालय कहाँ छ?",
                "मलाई मद्दत चाहिएको छ", "प्रहरीलाई बोलाउनुहोस्", "म हराएको छु", "मलाई भोक लागेको छ", "मलाई प्यास लागेको छ"
            ],
            'si': [
                "හෙලෝ", "ඔබ කොහොමද?", "ස්තූතියි", "සුභ උදෑසන", "සුභ සන්ධ්‍යාව",
                "ඔබේ නම කුමක්ද?", "මම හොඳින්", "ඔබ කොහෙන්ද?", "ඔබව හමුවීම සතුටක්",
                "පසුව හමුවමු", "ගිහින් එන්න", "කරුණාකර", "සමාවන්න", "මට සමාවන්න",
                "ඔව්", "නැහැ", "සමහර විට", "මට දන්නේ නැහැ", "මම තේරුම් ගනිමි", "මම තේරුම් නොගනිමි",
                "ඔබට මට උදව් කළ හැකිද?", "මේකට මිල කීයද?", "වැසිකිළිය කොහෙද?",
                "මට උදව් ඕන", "පොලිසියට කතා කරන්න", "මම නැතිවී ගියා", "මට බඩගිනියි", "මට පිපාසයි"
            ],
            'ta': [
                "வணக்கம்", "நீங்கள் எப்படி இருக்கிறீர்கள்?", "நன்றி", "காலை வணக்கம்", "மாலை வணக்கம்",
                "உங்கள் பெயர் என்ன?", "நான் நன்றாக இருக்கிறேன்", "நீங்கள் எங்கிருந்து வருகிறீர்கள்?", "உங்களை சந்தித்தது மகிழ்ச்சி",
                "பிறகு சந்திப்போம்", "பிரியாவிடை", "தயவுசெய்து", "மன்னிக்கவும்", "என்னை மன்னிக்கவும்",
                "ஆம்", "இல்லை", "ஒருவேளை", "எனக்குத் தெரியாது", "நான் புரிந்துகொள்கிறேன்", "நான் புரிந்துகொள்ளவில்லை",
                "நீங்கள் எனக்கு உதவ முடியுமா?", "இதற்கு எவ்வளவு செலவு?", "கழிப்பறை எங்கே?",
                "எனக்கு உதவி தேவை", "காவல்துறையை அழைக்கவும்", "நான் தொலைந்துவிட்டேன்", "எனக்கு பசிக்கிறது", "எனக்கு தாகமாக இருக்கிறது"
            ],
            'mr': [
                "नमस्कार", "तुम्ही कसे आहात?", "धन्यवाद", "सुप्रभात", "शुभ संध्या",
                "तुमचे नाव काय आहे?", "मी ठीक आहे", "तुम्ही कोठून आहात?", "तुम्हाला भेटून आनंद झाला",
                "नंतर भेटू", "निरोप", "कृपया", "माफ करा", "मला माफ करा",
                "होय", "नाही", "कदाचित", "मला माहीत नाही", "मी समजतो", "मी समजत नाही",
                "तुम्ही माझी मदत करू शकता?", "याची किंमत किती आहे?", "स्नानगृह कुठे आहे?",
                "मला मदत हवी", "पोलिसांना बोला", "मी हरवलो आहे", "मला भूक लागली आहे", "मला तहान लागली आहे"
            ]
        }
    
    def collect_parallel_corpus_data(self):
        """Collect parallel corpus data from various sources"""
        
        logger.info("Collecting parallel corpus data...")
        
        # Define language pairs
        language_pairs = [
            ('en', 'hi'), ('hi', 'en'),
            ('en', 'ne'), ('ne', 'en'),
            ('en', 'si'), ('si', 'en'),
            ('en', 'ta'), ('ta', 'en'),
            ('en', 'mr'), ('mr', 'en'),
        ]
        
        for source_lang, target_lang in language_pairs:
            logger.info(f"Collecting data for {source_lang}-{target_lang}")
            
            # Collect from multiple sources
            data = []
            
            # Add common phrases
            data.extend(self._get_common_phrases(source_lang, target_lang))
            
            # Add language-specific phrases
            data.extend(self._get_language_phrases(source_lang, target_lang))
            
            # Add generated sentences
            data.extend(self._generate_sentences(source_lang, target_lang))
            
            # Save data
            self._save_parallel_data(source_lang, target_lang, data)
            
            logger.info(f"✓ Collected {len(data)} samples for {source_lang}-{target_lang}")
    
    def _get_common_phrases(self, source_lang: str, target_lang: str) -> List[Tuple[str, str]]:
        """Get common phrases for translation"""
        
        if source_lang not in self.common_phrases:
            return []
        
        phrases = self.common_phrases[source_lang]
        data = []
        
        for phrase in phrases:
            # For demo purposes, create simple translations
            # In real implementation, use proper translation services
            translated = self._simple_translate(phrase, source_lang, target_lang)
            data.append((phrase, translated))
        
        return data
    
    def _get_language_phrases(self, source_lang: str, target_lang: str) -> List[Tuple[str, str]]:
        """Get language-specific phrases"""
        
        data = []
        
        # Get phrases from source language
        if source_lang in self.language_phrases:
            for phrase in self.language_phrases[source_lang]:
                translated = self._simple_translate(phrase, source_lang, target_lang)
                data.append((phrase, translated))
        
        # Get phrases from target language (reverse translation)
        if target_lang in self.language_phrases:
            for phrase in self.language_phrases[target_lang]:
                translated = self._simple_translate(phrase, target_lang, source_lang)
                data.append((translated, phrase))
        
        return data
    
    def _generate_sentences(self, source_lang: str, target_lang: str, num_sentences: int = 100) -> List[Tuple[str, str]]:
        """Generate synthetic sentences for training"""
        
        # Template sentences for different languages
        templates = {
            'en': [
                "I am going to {place}",
                "The {object} is {adjective}",
                "I like {food} very much",
                "Today is {day}",
                "I have {number} {items}",
                "The weather is {weather}",
                "I want to {action}",
                "This is my {relation}",
                "I live in {place}",
                "I work as a {profession}",
            ],
            'hi': [
                "मैं {place} जा रहा हूं",
                "{object} {adjective} है",
                "मुझे {food} बहुत पसंद है",
                "आज {day} है",
                "मेरे पास {number} {items} हैं",
                "मौसम {weather} है",
                "मैं {action} चाहता हूं",
                "यह मेरा {relation} है",
                "मैं {place} में रहता हूं",
                "मैं {profession} के रूप में काम करता हूं",
            ],
            'ne': [
                "म {place} जान्छु",
                "{object} {adjective} छ",
                "मलाई {food} धेरै मन पर्छ",
                "आज {day} हो",
                "मसँग {number} {items} छन्",
                "मौसम {weather} छ",
                "म {action} चाहन्छु",
                "यो मेरो {relation} हो",
                "म {place} मा बस्छु",
                "म {profession} को रूपमा काम गर्छु",
            ]
        }
        
        # Fillers for templates
        fillers = {
            'place': ['school', 'hospital', 'market', 'park', 'home'],
            'object': ['book', 'car', 'house', 'tree', 'mountain'],
            'adjective': ['big', 'small', 'beautiful', 'old', 'new'],
            'food': ['rice', 'bread', 'milk', 'fruit', 'vegetables'],
            'day': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
            'number': ['one', 'two', 'three', 'four', 'five'],
            'items': ['books', 'pens', 'cars', 'houses', 'trees'],
            'weather': ['sunny', 'rainy', 'cloudy', 'cold', 'hot'],
            'action': ['eat', 'sleep', 'work', 'play', 'study'],
            'relation': ['father', 'mother', 'brother', 'sister', 'friend'],
            'profession': ['teacher', 'doctor', 'engineer', 'student', 'farmer'],
        }
        
        data = []
        
        if source_lang in templates:
            source_templates = templates[source_lang]
            
            for _ in range(num_sentences):
                # Select random template
                template = random.choice(source_templates)
                
                # Fill template with random fillers
                sentence = template
                for key, values in fillers.items():
                    if f"{{{key}}}" in sentence:
                        sentence = sentence.replace(f"{{{key}}}", random.choice(values))
                
                # Translate sentence
                translated = self._simple_translate(sentence, source_lang, target_lang)
                data.append((sentence, translated))
        
        return data
    
    def _simple_translate(self, text: str, source_lang: str, target_lang: str) -> str:
        """Simple translation function (replace with actual translation service)"""
        
        # This is a placeholder - in real implementation, use proper translation
        # For now, return a simple transformation
        if source_lang == target_lang:
            return text
        
        # Simple word-level translations for demo
        translations = {
            'en-hi': {
                'hello': 'नमस्ते',
                'how are you': 'आप कैसे हैं',
                'thank you': 'धन्यवाद',
                'good morning': 'सुप्रभात',
                'good evening': 'शुभ संध्या',
            },
            'hi-en': {
                'नमस्ते': 'hello',
                'आप कैसे हैं': 'how are you',
                'धन्यवाद': 'thank you',
                'सुप्रभात': 'good morning',
                'शुभ संध्या': 'good evening',
            },
            'en-ne': {
                'hello': 'नमस्कार',
                'how are you': 'तपाईं कसरी हुनुहुन्छ',
                'thank you': 'धन्यवाद',
                'good morning': 'शुभ बिहान',
                'good evening': 'शुभ साँझ',
            },
            'ne-en': {
                'नमस्कार': 'hello',
                'तपाईं कसरी हुनुहुन्छ': 'how are you',
                'धन्यवाद': 'thank you',
                'शुभ बिहान': 'good morning',
                'शुभ साँझ': 'good evening',
            }
        }
        
        key = f"{source_lang}-{target_lang}"
        if key in translations:
            for word, translation in translations[key].items():
                if word.lower() in text.lower():
                    return text.replace(word, translation)
        
        # If no specific translation found, return generic
        return f"[{target_lang.upper()}] {text}"
    
    def _save_parallel_data(self, source_lang: str, target_lang: str, data: List[Tuple[str, str]]):
        """Save parallel data to CSV file"""
        
        df = pd.DataFrame(data, columns=['source', 'target'])
        filename = f"{source_lang}-{target_lang}.csv"
        filepath = self.output_dir / filename
        df.to_csv(filepath, index=False)
        
        logger.info(f"Saved {len(data)} samples to {filepath}")
    
    def collect_ocr_data(self):
        """Collect OCR training data"""
        
        logger.info("Collecting OCR training data...")
        
        # This would involve collecting images with text in different languages
        # For now, create a placeholder structure
        
        ocr_data = {
            'en': [],
            'hi': [],
            'ne': [],
            'si': [],
            'ta': [],
            'mr': []
        }
        
        # Sample OCR data structure
        for lang in ocr_data.keys():
            ocr_data[lang] = [
                {
                    'image_path': f'sample_{lang}_1.jpg',
                    'text': f'Sample text in {lang}',
                    'bboxes': [[0, 0, 100, 50], [0, 60, 100, 110]]
                },
                {
                    'image_path': f'sample_{lang}_2.jpg',
                    'text': f'Another sample in {lang}',
                    'bboxes': [[0, 0, 150, 50]]
                }
            ]
        
        # Save OCR data
        ocr_file = self.output_dir / 'ocr_data.json'
        with open(ocr_file, 'w', encoding='utf-8') as f:
            json.dump(ocr_data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"✓ OCR data saved to {ocr_file}")
    
    def collect_asr_data(self):
        """Collect ASR training data"""
        
        logger.info("Collecting ASR training data...")
        
        # This would involve collecting audio files with transcriptions
        # For now, create a placeholder structure
        
        asr_data = {
            'en': [],
            'hi': [],
            'ne': [],
            'si': [],
            'ta': [],
            'mr': []
        }
        
        # Sample ASR data structure
        for lang in asr_data.keys():
            asr_data[lang] = [
                {
                    'audio_path': f'sample_{lang}_1.wav',
                    'text': f'Sample audio transcription in {lang}',
                    'duration': 5.2,
                    'sample_rate': 16000
                },
                {
                    'audio_path': f'sample_{lang}_2.wav',
                    'text': f'Another audio sample in {lang}',
                    'duration': 3.8,
                    'sample_rate': 16000
                }
            ]
        
        # Save ASR data
        asr_file = self.output_dir / 'asr_data.json'
        with open(asr_file, 'w', encoding='utf-8') as f:
            json.dump(asr_data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"✓ ASR data saved to {asr_file}")
    
    def create_data_summary(self):
        """Create a summary of collected data"""
        
        logger.info("Creating data summary...")
        
        summary = {
            'collection_date': str(pd.Timestamp.now()),
            'total_files': len(list(self.output_dir.glob('*.csv'))) + len(list(self.output_dir.glob('*.json'))),
            'language_pairs': [],
            'total_samples': 0
        }
        
        # Count samples in each CSV file
        for csv_file in self.output_dir.glob('*.csv'):
            df = pd.read_csv(csv_file)
            pair = csv_file.stem
            summary['language_pairs'].append({
                'pair': pair,
                'samples': len(df)
            })
            summary['total_samples'] += len(df)
        
        # Save summary
        summary_file = self.output_dir / 'data_summary.json'
        with open(summary_file, 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        logger.info(f"✓ Data summary saved to {summary_file}")
        logger.info(f"Total samples collected: {summary['total_samples']}")

def main():
    parser = argparse.ArgumentParser(description="Collect training data for translation models")
    parser.add_argument("--output_dir", type=str, default="training_data", help="Output directory for collected data")
    parser.add_argument("--collect_parallel", action="store_true", help="Collect parallel corpus data")
    parser.add_argument("--collect_ocr", action="store_true", help="Collect OCR training data")
    parser.add_argument("--collect_asr", action="store_true", help="Collect ASR training data")
    parser.add_argument("--create_summary", action="store_true", help="Create data summary")
    
    args = parser.parse_args()
    
    collector = DataCollector(args.output_dir)
    
    if args.collect_parallel:
        collector.collect_parallel_corpus_data()
    
    if args.collect_ocr:
        collector.collect_ocr_data()
    
    if args.collect_asr:
        collector.collect_asr_data()
    
    if args.create_summary:
        collector.create_data_summary()
    
    logger.info("Data collection completed!")

if __name__ == "__main__":
    main()
