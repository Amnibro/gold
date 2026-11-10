import json,os,re,subprocess,sys,time
R=os.path.dirname(os.path.abspath(__file__))
def sh(c,cwd,inp=None,env=None):
    e=dict(os.environ);e.update(env or {})
    t=time.perf_counter();p=subprocess.run(c,shell=True,cwd=cwd,input=inp,capture_output=True,env=e);return time.perf_counter()-t,p.stdout,p.returncode
def tok(cwd,files): return sum(int(subprocess.run([R+'/ctok.sh',os.path.join(cwd,f)],capture_output=True,text=True).stdout.strip() or 0) for f in files)
def norm(m,b):
    s=b.decode('utf8','replace')
    for a,r in m.get('norm',[]): s=re.sub(a,r,s)
    return s.split('\n')
def run(d):
    cwd=os.path.join(R,d);m=json.load(open(cwd+'/meta.json'));cases=open(cwd+'/'+m['cases'],'rb').read()
    _,ro,_=sh(m['run_orig'],cwd,cases);_,ho,_=sh(m['run_he'],cwd,cases)
    ra,rb=ro.decode('utf8','replace').split('\n'),ho.decode('utf8','replace').split('\n');a,b=norm(m,ro),norm(m,ho);n=len(ra)-(1 if ra[-1]=='' else 0)
    exact=sum(1 for x,y in zip(ra[:n],rb[:n]) if x==y);same=sum(1 for x,y in zip(a[:n],b[:n]) if x==y)
    res={'id':d,**{k:m[k] for k in('product','module','orig_lang','note','norm_note') if k in m},'cases':n,'exact':exact,'match':same}
    reps=str(m.get('reps',1));tm={};X=m.get('extra',[]);xr=str(m.get('extra_reps',reps));xt={}
    for c in m.get('build',[]):
        if sh(c,cwd)[2]: sys.exit('build failed: '+c)
    def best(cs,n,to,sfx=''):
        ts={k:[] for k,_ in cs}
        for _ in range(int(m.get('runs',5))):
            for k,c in cs:
                t,o,rc=sh(c,cwd,cases,{'REPS':n});ts[k].append(t);res['check_'+k+sfx]=o.strip().decode()[:40]
        for k,_ in cs: to[k]=round(min(ts[k]),4)
    best([('orig',m['run_orig']),('helium',m['run_he'])],reps,tm)
    H=sorted({x.get('he',m['run_he']) for x in X},key=lambda h:h!=m['run_he']);hn={h:'helium' if h==m['run_he'] else 'helium_'+str(i) for i,h in enumerate(H)}
    if X: best([(hn[h],h) for h in H]+[(x['name'],x['cmd']) for x in X],xr,xt,'_x');res['extra']={'reps':int(xr),'labels':{x['name']:x['label'] for x in X},'he':{x['name']:hn[x.get('he',m['run_he'])] for x in X},'time':xt}
    res['time']=tm;res['speedup']=round(tm['orig']/tm['helium'],2);res['reps']=int(reps)
    G=m['gold'] if isinstance(m['gold'],list) else [m['gold']]
    res['tokens']={'orig':tok(cwd,m['orig_src']),'gold':tok(cwd,G),'helium':tok(cwd,m['helium'])}
    res['lines']={'orig':sum(len(open(cwd+'/'+f).read().splitlines()) for f in m['orig_src']),'gold':sum(len(open(cwd+'/'+f).read().splitlines()) for f in G),'helium':sum(len(open(cwd+'/'+f).read().splitlines()) for f in m['helium'])}
    return res
if __name__=='__main__':
    ds=sys.argv[1:] or sorted(x for x in os.listdir(R) if os.path.exists(os.path.join(R,x,'meta.json')))
    out=json.load(open(R+'/results.json')) if os.path.exists(R+'/results.json') else {}
    for d in ds:
        r=run(d);out[d]=r;print(json.dumps(r))
        json.dump(out,open(R+'/results.json','w'),indent=1)
