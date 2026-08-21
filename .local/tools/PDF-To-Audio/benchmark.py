import sys
import time
import unittest.mock as mock

class DummyPage:
    def extract_text(self):
        return "Dummy text"
    def extractText(self):
        return "Dummy text"

class DummyPdf:
    def __init__(self):
        self.pages = [DummyPage() for _ in range(100)] # 100 pages

import PyPDF2
class MockPdfReader:
    def __init__(self, f):
        self.pdf = DummyPdf()
        self.pages = self.pdf.pages
PyPDF2.PdfReader = MockPdfReader

import builtins
original_open = builtins.open
def mock_open(file, *args, **kwargs):
    if file == "dummy.pdf":
        return mock.mock_open(read_data=b"")()
    return original_open(file, *args, **kwargs)
builtins.open = mock_open

# Mock pyttsx3 and tkinter
mock_tkinter = mock.Mock()
mock_tkinter.Tk.return_value.withdraw = mock.Mock()
sys.modules['tkinter'] = mock_tkinter
mock_askopenfilename = mock.Mock()
mock_askopenfilename.return_value = "dummy.pdf"
sys.modules['tkinter.filedialog'] = mock.Mock(askopenfilename=mock_askopenfilename)

# Mock gtts
mock_gtts = mock.Mock()
sys.modules['gTTS'] = mock_gtts
sys.modules['gtts'] = mock.Mock(gTTS=mock_gtts)

class MockEngine:
    def say(self, text):
        pass
    def runAndWait(self):
        pass

def slow_init():
    time.sleep(0.05)
    return MockEngine()

mock_pyttsx3 = mock.Mock()
mock_pyttsx3.init.side_effect = slow_init
sys.modules['pyttsx3'] = mock_pyttsx3

start = time.time()
with original_open(".local/tools/PDF-To-Audio/pdf_to_audio.py") as f:
    code = f.read()
try:
    exec(code, globals())
except Exception as e:
    print(f"Error: {e}")
end = time.time()
print(f"Execution time on mocked 100 pages: {end-start:.4f}s")
