#!/usr/bin/python

import wikipedia
import sys

page_content = wikipedia.page(sys.argv[1]).content
print(page_content)

