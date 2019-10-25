import setuptools
with open("README.md", "r") as fh:
    long_description = fh.read()
setuptools.setup(
  name='RsyncRotateBackup',
  version='0.0',
  scripts=['bin/rsync-rotate-backup'] ,
  author="Fmajor",
  author_email="wujinnnnn@gmail.com",
  description="A python script to do rotation backups using rsync",
  long_description=long_description,
  long_description_content_type="text/markdown",
  url="https://github.com/Fmajor/rsync-rotate-backup",
  packages=setuptools.find_packages(),
  classifiers=[
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
  ]
  install_requires=[
    dateutil,
    argparse,
    calendar,
    yaml,
  ],
 )
