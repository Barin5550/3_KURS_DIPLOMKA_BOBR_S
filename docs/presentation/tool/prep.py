import sys,glob,os
from PIL import Image, ImageDraw
src=sys.argv[1]; out=sys.argv[2]
def phone(name):
    im=Image.open(f'{src}/{name}.png').convert('RGB')
    W=540; im=im.resize((W,int(im.height*W/im.width)),Image.LANCZOS)
    b=16; R=56
    fw,fh=W+2*b,im.height+2*b
    frame=Image.new('RGBA',(fw,fh),(0,0,0,0))
    d=ImageDraw.Draw(frame); d.rounded_rectangle([0,0,fw-1,fh-1],R,fill=(10,20,48,255))
    mask=Image.new('L',im.size,0); ImageDraw.Draw(mask).rounded_rectangle([0,0,im.width-1,im.height-1],R-b,fill=255)
    frame.paste(im,(b,b),mask)
    frame.save(f'{out}/{name}.png')
def wide(name,W=1600):
    im=Image.open(f'{src}/{name}.png').convert('RGB')
    im=im.resize((W,int(im.height*W/im.width)),Image.LANCZOS)
    b=12;R=24
    fw,fh=W+2*b,im.height+2*b
    frame=Image.new('RGBA',(fw,fh),(0,0,0,0))
    ImageDraw.Draw(frame).rounded_rectangle([0,0,fw-1,fh-1],R,fill=(10,20,48,255))
    mask=Image.new('L',im.size,0); ImageDraw.Draw(mask).rounded_rectangle([0,0,im.width-1,im.height-1],R-b,fill=255)
    frame.paste(im,(b,b),mask); frame.save(f'{out}/{name}.png')
for f in sorted(glob.glob(src+'/*.png')):
    n=os.path.basename(f)[:-4]
    (wide if n.startswith(('22','23','24')) else phone)(n)
    im=Image.open(f'{out}/{n}.png'); print(n, im.size)
