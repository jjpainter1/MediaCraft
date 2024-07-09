Install Command
iwr -useb https://raw.githubusercontent.com/jjpainter1/MediaCraft/main/install.ps1 | iex


Pushing Updates to GitHub

git add . (adds all new files and changes)
git commit -m "Update MediaCraft" (commits the changes)
git push origin main (pushes the changes to the remote repository)







#In your Python code, when you need to use oiiotool, construct the path like this

import os
import subprocess

oiiotool_path = os.path.join('third_party', 'openimageio-2.6.2.0dev', 'oiiotool.exe')

# Use subprocess to run oiiotool
subprocess.run([oiiotool_path, '--version'])


