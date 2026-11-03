import re,sys,json,random,math
src=open(sys.argv[1]).read();root=sys.argv[2];n=int(sys.argv[3]);random.seed(int(sys.argv[4]) if len(sys.argv)>4 else 7)
S={}
for m in re.finditer(r'struct\s+(\w+)\s*\{(.*?)\n\}',src,re.S):
    fs=[]
    for l in m.group(2).split('\n'):
        d='serde(default)' in l
        f=re.search(r'pub\s+(\w+)\s*:\s*([^,]+?),?\s*$',l)
        if f: fs.append((f.group(1),f.group(2).strip(),d))
    S[m.group(1)]=fs
lits=sorted(set(re.findall(r'"([A-Za-z][A-Za-z0-9_ \-]{0,30})"\s*(?:=>|\|)',src)+re.findall(r'==\s*"([A-Za-z][A-Za-z0-9_ \-]{0,30})"',src))) or sorted(set(re.findall(r'"([A-Za-z][A-Za-z0-9_ \-]{0,30})"',src)))
def num(name):
    k=name.lower()
    r=random.random()
    if r<0.04: return 0.0
    if r<0.07: return -round(random.uniform(0.1,50),4)
    for keys,lo,hi in [(('modulus','e_mod','young'),1e9,3e11),(('diam','thick','width','height','length','radius','depth','span','pitch','gap','clear','free','x','pos','dist'),1e-3,2.0),(('force','load','torque','moment','shear_f','axial'),1,1e5),(('temp','t_hot','t_cold','t_amb'),-40,600),(('press','stress','strength','yield','ultimate','ut','sy','su'),1e6,1.5e9),(('coil','count','num','n_','turns','cycles'),1,40),(('poisson','nu','eff','emiss','factor','ratio','frac','coef','mu'),0.01,0.9),(('k','cond'),0.02,400),(('h_conv','h_'),2,500),(('alpha','expan'),1e-6,3e-5)]:
        if any(x in k for x in keys): return float('%.6g'%math.exp(random.uniform(math.log(lo) if lo>0 else 0,math.log(hi)))) if lo>0 else round(random.uniform(lo,hi),3)
    return float('%.6g'%random.uniform(0.1,100))
def val(name,t,depth=0):
    t=t.strip()
    m=re.match(r'Option<(.*)>$',t)
    if m: return None if random.random()<0.3 else val(name,m.group(1),depth)
    m=re.match(r'Vec<(.*)>$',t)
    if m: return [val(name,m.group(1),depth+1) for _ in range(random.randint(0,5 if depth<2 else 2))]
    m=re.match(r'\[(.*);\s*(\d+)\]$',t)
    if m: return [val(name,m.group(1),depth+1) for _ in range(int(m.group(2)))]
    if t in('f64','f32'): return num(name)
    if t in('usize','u32','u64','i32','i64','u8','u16'): return random.randint(0,6) if random.random()<0.2 else random.randint(1,12)
    if t=='bool': return random.random()<0.5
    if t=='String' or t=='&str': return random.choice(lits) if lits and random.random()<0.9 else 'zzz'
    if t in S: return obj(t,depth+1)
    return None
def obj(sn,depth=0):
    o={}
    for f,t,d in S[sn]:
        if (d or t.startswith('Option')) and random.random()<0.25: continue
        v=val(f,t,depth)
        if v is None and not t.startswith('Option'): continue
        o[f]=v
    return o
for i in range(n):
    if i==0: print('not json'); continue
    if i==1: print('{}'); continue
    print(json.dumps(obj(root)))
