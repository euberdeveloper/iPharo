# JupyterTalk
Basic Pharo Smaltalk kernel for Jupyter. This project is implemented on Pharo 6.1 64 bits and Mac Os X. 
It uses ZeroMQ ported from http://smalltalkhub.com/#!/~panuw/zeromq project to uFFI.
Roassal integration supported.
TO-DO:
- Improve ZeroMQ API.
- Review display API.
- Widgets support.
- Installation procedure.
- 32 bits version? ZMQ is 64 a bits library on Mac Os.
- Tests...

### install Solar
```Smalltalk
Metacello new 
	baseline: 'JupyterTalk';
	repository: 'github://jmari/JupyterTalk';
	load:'all'
```
Create the folder	'/usr/local/share/jupyter/kernels/pharo'. Create file	'kernel.json' with contents
```JSON
'{
  "argv": [
    "/Applications/Pharo6.1-64_ZeroMQ.app/Contents/MacOS/Pharo",
    "/Applications/Pharo6.1-64_ZeroMQ.app/Contents/Resources/Pharo6.1-64.image",
    "ipharo",
    "{connection_file}"
  ],
  "display_name": "Pharo Smalltalk",
  "language": "smalltalk"
}'
```
Optional, copy an icon with file name logo-64x64.png.
