Install Command
iwr -useb https://raw.githubusercontent.com/jjpainter1/MediaCraft/main/install.ps1 | iex









#In your Python code, when you need to use oiiotool, construct the path like this

import os
import subprocess

oiiotool_path = os.path.join('third_party', 'openimageio-2.6.2.0dev', 'oiiotool.exe')

# Use subprocess to run oiiotool
subprocess.run([oiiotool_path, '--version'])


