@echo off
echo Fixing asset file permissions...
attrib -R "assets\images\gif\*.*" /s
attrib -R "assets\images\png\*.*" /s
attrib -R "assets\images\svg\*.*" /s
echo Asset permissions fixed!
