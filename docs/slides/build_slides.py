import random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR

W,H=1920,1080
FONT="C:/Windows/Fonts/malgun.ttf"; FONTB="C:/Windows/Fonts/malgunbd.ttf"

def make_bg(path):
    # dark -> purple diagonal gradient with light swooshes in the top-right corner (similar to the supplied slides)
    import numpy as np
    y,x=np.mgrid[0:H,0:W]
    t=(x/W*0.55+y/H*0.75)
    t=np.clip(t,0,1)**1.6
    c0=np.array([8,4,16]); c1=np.array([96,24,168])
    img=(c0[None,None,:]*(1-t[...,None])+c1[None,None,:]*t[...,None]).astype(np.uint8)
    base=Image.fromarray(img)
    sw=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(sw)
    for k,(a,col) in enumerate([(70,(200,170,255)),(110,(240,220,255)),(50,(150,110,255))]):
        pts=[]
        for i in range(0,101):
            u=i/100
            px=W*(0.52+0.5*u)+k*10
            py=-40+ (1-math.cos(u*math.pi*0.9))*(150+k*30)*0.8 + k*18 - u*60
            pts.append((px,py))
        d.line(pts,fill=col+(a,),width=3+k*2)
    sw=sw.filter(ImageFilter.GaussianBlur(2))
    base=base.convert('RGBA'); base.alpha_composite(sw)
    # soft glow bottom-right
    glow=Image.new('RGBA',(W,H),(0,0,0,0)); gd=ImageDraw.Draw(glow)
    gd.ellipse((W*0.7,H*0.55,W*1.2,H*1.4),fill=(150,60,255,70)); glow=glow.filter(ImageFilter.GaussianBlur(120))
    base.alpha_composite(glow)
    base.convert('RGB').save(path)

SLIDES=[
 dict(size=36, items=[
  ('title',"3강. MCP x Verse 게임플레이 루프 : 타임어택 & 매치 시스템"),('gap',),
  ('h',"1. 학습 목표"),
  ('b',"1~2강에서 배치한 체크포인트·결승선·장애물에 실제 Verse 로직 연결"),
  ('b',"5분 타임어택 카운트다운 및 플레이어별 골인 기록 시스템 구현"),
  ('b',"전원 골인 또는 시간 종료 시 순위·기록을 보여주는 매치 종료 화면 완성"),('gap',),
  ('h','2. 핵심 가치:  승패 판정·기록·순위·사운드 피드백을 갖춘 "플레이 가능한 게임"으로 완성'),('gap',),
  ('h',"3. MCP 활용 세부 내용"),
  ('b',"MCP가 find_actors로 장치를 조회하고 @editable 칸에 자동 연결"),
  ('b',"플레이어별 상태([player] 맵: 체크포인트 수, 골인 순위·시간)를 MCP가 설계·작성"),
  ('b',"종료 조건 판정·순위 계산을 MCP가 생성하고 BuildAll 컴파일과 로그로 검증"),('gap',),
  ('h',"4. 학습 결과물"),
  ('b',"타임어택 카운트다운 + 플레이어별 골인 기록 시스템"),
  ('b',"체크포인트 진행도·실시간 순위 HUD와 결과 화면(순위·걸린 시간)"),
  ('b',"이벤트 사운드·배경음악까지 갖춘, 1~3강을 통해 완성된 게임"),
 ]),
 dict(size=34, items=[
  ('title',"게임플레이 루프 구성도"),('gap',),
  ('h',"1. race_manager (creative_device)"),
  ('b',"5분 카운트다운, 골인 감지·기록, 체크포인트 진행도, 실시간 순위, 마지막 10초 알람, 결과 화면, 게임 종료"),('gap',),
  ('h',"2. 체크포인트 패드 (player_checkpoint_device)"),
  ('b',"낙사 후 리스폰은 장치 기본 기능이 처리, Verse는 밟은 개수만 집계해 HUD에 표시"),('gap',),
  ('h',"3. flipper_knockback"),
  ('b',"플리퍼·기둥·주먹에 닿으면 바운서를 발밑으로 보내 튕겨냄"),('gap',),
  ('h',"4. seesaw_controller"),
  ('b',"시소 2개를 기울이고, 위의 범퍼 기둥 8개가 시소 중심을 돌며 튕겨냄"),('gap',),
  ('h',"5. sfx_manager"),
  ('b',"리스폰·낙사·체크포인트·에어벤트 바람 소리를 상태 변화로 감지해 재생"),('gap',),
  ('h',"6. 결과 화면 / HUD (race_manager 안에서 구성)"),
  ('b',"위: 타이머·체크포인트 / 왼쪽 아래: 순위(1ST / 4) / 전체: 결과(순위·걸린 시간 또는 TIME OVER!)"),
 ]),
 dict(size=31, items=[
  ('title',"강의 상세 워크플로우"),('gap',),
  ('h',"1) 장치 조회 및 Verse 연결"),
  ('b',"실습내용: MCP가 find_actors로 체크포인트·결승선 장치를 찾아 @editable 칸에 자동 연결하고, 값을 다시 읽어 검증"),
  ('h',"2) 플레이어별 상태 추적 자료구조 설계"),
  ('b',"실습내용: [player]int(체크포인트 수), [agent]int(순위·시간) 맵을 쓰는 코드를 MCP에게 요청 → VerseToolset.WriteFile로 파일 생성"),
  ('h',"3) 타임어택 타이머와 골인 로직 작성"),
  ('b',"실습내용: 카운트다운과 결승선 감지를 연결, 골인 시 시간 정지·기록 저장 → BuildAll로 컴파일 검증"),
  ('h',"4) 체크포인트 진행도와 낙사 처리"),
  ('b',"실습내용: '처음 밟음' 이벤트로 진행도 집계, 낙사는 장치 기본 리스폰, 죽음·리스폰 소리는 상태 변화 감지로 재생"),
  ('h',"5) 매치 종료와 결과 화면"),
  ('b',"실습내용: 시간 초과 또는 전원 골인 판정 → 순위·걸린 시간 결과 화면 표시 → End Game 작동"),
  ('h',"6) 사운드와 HUD 마무리"),
  ('b',"실습내용: 직접 만든 wav를 가져와 Audio Player 연결 후 Play(Agent), 마지막 10초 알람과 순위 HUD 추가"),
  ('h',"7) 통합 플레이테스트"),
  ('b',"실습내용: 전체 게임을 처음부터 끝까지 플레이 → 장애물·체크포인트·타이머·순위·소리 검증, 로그와 녹화로 문제를 찾아 수정"),
 ]),
]

def layout(sl, f, fb, maxw):
    """return list of (x,y,text,bold) lines for drawing"""
    size=sl['size']; out=[]; y=60
    d=ImageDraw.Draw(Image.new('RGB',(10,10)))
    for it in sl['items']:
        k=it[0]
        if k=='gap': y+=int(size*0.7); continue
        txt=it[1]; bold=(k=='title')
        fnt=fb if bold else f
        if k=='h': x0=70+int(size*0.9)
        elif k=='b': x0=70+int(size*0.9)+int(size*1.0); txt='• '+txt
        else: x0=70
        # wrap
        words=list(txt); cur=''; lines=[]
        hang = x0 + (d.textlength('• ',font=fnt) if k=='b' else 0)
        for ch in txt:
            if d.textlength(cur+ch,font=fnt)+x0 > maxw: lines.append(cur); cur=ch
            else: cur+=ch
        lines.append(cur)
        for i,ln in enumerate(lines):
            out.append(((x0 if i==0 else hang), y, ln.lstrip() if i>0 else ln, bold, k))
            y+=int(size*1.5)
    return out,y

make_bg('bg.png')
fcache={}
prs=Presentation(); prs.slide_width=Inches(13.333); prs.slide_height=Inches(7.5)
for n,sl in enumerate(SLIDES,1):
    f=ImageFont.truetype(FONT,sl['size']); fb=ImageFont.truetype(FONTB,sl['size'])
    lines,ybot=layout(sl,f,fb,W-90)
    print('slide',n,'bottom y',ybot)
    img=Image.open('bg.png').convert('RGB'); d=ImageDraw.Draw(img)
    for x,y,t,b,k in lines:
        d.text((x,y),t,font=(fb if b else f),fill=(255,255,255))
    img.save(f'slide{n}.png')
    # pptx: picture background + editable text
    s=prs.slides.add_slide(prs.slide_layouts[6])
    s.shapes.add_picture('bg.png',0,0,width=prs.slide_width,height=prs.slide_height)
    tb=s.shapes.add_textbox(Inches(0.45),Inches(0.35),Inches(12.4),Inches(6.9)); tf=tb.text_frame; tf.word_wrap=True
    first=True
    for it in sl['items']:
        k=it[0]
        p=tf.paragraphs[0] if first else tf.add_paragraph(); first=False
        if k=='gap':
            p.text=''; p.font.size=Pt(sl['size']/2*0.5); continue
        r=p.add_run(); r.text=('• ' if k=='b' else '')+it[1]
        r.font.size=Pt(sl['size']/2); r.font.name='맑은 고딕'; r.font.bold=(k=='title'); r.font.color.rgb=RGBColor(255,255,255)
        if k in('h',): p.level=0; 
        if k=='h': p.space_before=Pt(2)
        if k=='b': 
            from pptx.util import Pt as P
            p.paragraph_format = None if False else None
        if k in ('h','b'):
            pPr=p._p.get_or_add_pPr(); pPr.set('marL',str(int(Emu(Inches(0.3 if k=='h' else 0.6))))); pPr.set('indent','0' if k=='h' else str(-int(Emu(Inches(0.0)))))
prs.save('3강_슬라이드_현재기준.pptx')
