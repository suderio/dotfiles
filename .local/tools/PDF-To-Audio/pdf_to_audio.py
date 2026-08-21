# -*- coding: utf-8 -*-
"""
Created on Sun Oct 11 19:50:06 2020

@author: quent
"""
import PyPDF2
import pyttsx3
import sys
from gtts import gTTS  # pip install gTTS
from tkinter import Tk
from tkinter.filedialog import askopenfilename

def process_pdf(file_path, speak=True, save_audio=True):
    with open(file_path, "rb") as f:  # open the file in reading (rb) mode and call it f
        pdf = PyPDF2.PdfReader(f)
        texts = []
        if speak:
            engine = pyttsx3.init()
        # parse every page
        for page in pdf.pages:
            try:
                text = page.extract_text()
            except AttributeError:
                text = page.extractText()
            texts.append(text)
            if speak:
                ## speaking part ####
                engine.say(text)
                engine.runAndWait()
        txt_file = "".join(texts)

    if save_audio:
        audio_file = gTTS(text=txt_file, lang='en')  # stores into variable
        # saves into mp3 format with the same name of pdf in the same directory where pdf is
        audio_file.save(file_path.split('.')[0] + ".mp3")

    return txt_file

if __name__ == '__main__':
    if len(sys.argv) > 1:
        FILE_PATH = sys.argv[1]
    else:
        Tk().withdraw()  # We could make our own GUI but let's use the default one
        FILE_PATH = askopenfilename()  # open the dialog GUI
    if FILE_PATH:
        process_pdf(FILE_PATH)
