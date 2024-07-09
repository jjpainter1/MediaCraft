# setuptools is a package that simplifies the creation of Python packages.
# If you're seeing an unresolved import warning, ensure setuptools is installed
# in your virtual environment and that your IDE is configured to use the correct
# Python interpreter.
from setuptools import setup, find_packages
import os

def get_files(directory):
    file_list = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_list.append(os.path.join(root, file))
    return file_list

# Function to conditionally include data files
def get_data_files():
    data_files = [
        ('', ['mediacraft.bat']),
        ('third_party/python', get_files('third_party/python')),
        ('venv', get_files('venv')),
    ]
    
    # Include OpenImageIO only if the directory exists
    if os.path.exists('third_party/openimageio-2.6.2.0dev'):
        data_files.append(('third_party/openimageio-2.6.2.0dev', get_files('third_party/openimageio-2.6.2.0dev')))
    
    # Include FFmpeg only if the directory exists
    if os.path.exists('third_party/ffmpeg'):
        data_files.append(('third_party/ffmpeg', get_files('third_party/ffmpeg')))
    
    return data_files

setup(
    name="MediaCraft",
    version="0.1",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,
    install_requires=[
        "colorama==0.4.6",
    ],
    entry_points={
        "console_scripts": [
            "mediacraft=mediacraft.main:main",
        ],
    },
    # Include the Python interpreter, venv, and third-party tools
    data_files=get_data_files(),
)