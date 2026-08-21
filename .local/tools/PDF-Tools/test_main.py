import os
import pytest
from unittest.mock import patch, mock_open, MagicMock
from main import (
    merge_pdfs, split_pdfs, add_watermark, add_encryption, rotate_pages,
    reorder_pages, ifPageExists
)
from PyPDF2 import PdfWriter

@pytest.fixture
def dummy_pdf():
    writer = PdfWriter()
    writer.add_blank_page(width=72, height=72)
    with open('dummy.pdf', 'wb') as f:
        writer.write(f)
    yield 'dummy.pdf'
    if os.path.exists('dummy.pdf'):
        os.remove('dummy.pdf')

@pytest.fixture
def dummy_watermark():
    writer = PdfWriter()
    writer.add_blank_page(width=72, height=72)
    with open('watermark.pdf', 'wb') as f:
        writer.write(f)
    yield 'watermark.pdf'
    if os.path.exists('watermark.pdf'):
        os.remove('watermark.pdf')

@patch('builtins.input')
def test_merge_pdfs(mock_input, dummy_pdf):
    mock_input.return_value = dummy_pdf
    merge_pdfs()
    assert os.path.exists('merged.pdf')
    os.remove('merged.pdf')

@patch('builtins.input')
def test_split_pdfs(mock_input, dummy_pdf):
    mock_input.return_value = dummy_pdf
    split_pdfs()
    assert os.path.exists('split0.pdf')
    os.remove('split0.pdf')

@patch('builtins.input')
def test_add_watermark(mock_input, dummy_pdf, dummy_watermark):
    mock_input.side_effect = [dummy_pdf, dummy_watermark]
    add_watermark()
    assert os.path.exists('watermarked-pdf.pdf')
    os.remove('watermarked-pdf.pdf')

@patch('builtins.input')
def test_add_encryption(mock_input, dummy_pdf):
    mock_input.side_effect = [dummy_pdf, 'password']
    add_encryption()
    assert os.path.exists('encrypted.pdf')
    os.remove('encrypted.pdf')

@patch('builtins.input')
def test_rotate_pages_clockwise(mock_input, dummy_pdf):
    mock_input.side_effect = [dummy_pdf, 'clockwise']
    rotate_pages()
    assert os.path.exists('rotated.pdf')
    os.remove('rotated.pdf')

@patch('builtins.input')
def test_rotate_pages_counterclockwise(mock_input, dummy_pdf):
    mock_input.side_effect = [dummy_pdf, 'counterclockwise']
    rotate_pages()
    assert os.path.exists('rotated.pdf')
    os.remove('rotated.pdf')

def test_ifPageExists():
    assert ifPageExists(5, 6) == True
    assert ifPageExists(5, 5) == False

@patch('builtins.input')
def test_reorder_pages(mock_input, dummy_pdf):
    # n=0 implies 0 pages to reorder, saving file as 'reordered.pdf'
    mock_input.side_effect = [dummy_pdf, '0', 'reordered']
    reorder_pages()
    assert os.path.exists('reordered.pdf')
    os.remove('reordered.pdf')
