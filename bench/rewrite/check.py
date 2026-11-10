import json,os,re,subprocess,sys
R=os.path.dirname(os.path.abspath(__file__));H=os.environ.get('GOLD_HELIUM',os.path.expanduser('~/ai/amni-lang/helium'))
d=sys.argv[1];cwd=os.path.join(R,d);m=json.load(open(cwd+'/meta.json'))
drv=[f for f in os.listdir(cwd+'/he') if f in('drive.he','drive.amni')][0]
b=subprocess.run([H+'/build/hcn','build',drv,'-o','drive'],cwd=cwd+'/he',env={**os.environ,'HC_LIB':H+'/hc/lib'},capture_output=True,text=True)
if b.returncode:print('driver does not compile:\n'+(b.stdout+b.stderr)[-3000:]);sys.exit(1)
cases=open(cwd+'/'+m['cases'],'rb').read();cl=cases.decode('utf8','replace').split('\n')
p=subprocess.run(m['run_he'],shell=True,cwd=cwd,input=cases,capture_output=True)
ref=open(cwd+'/ref.out','rb').read().decode('utf8','replace')
def norm(s):
    for a,r in m.get('norm',[]):s=re.sub(a,r,s)
    return s
a,o=ref.split('\n'),p.stdout.decode('utf8','replace').split('\n');n=len(a)-(1 if a[-1]=='' else 0)
bad=[i for i in range(n) if i>=len(o) or norm(o[i])!=norm(a[i])]
if p.returncode:print(f'driver exited {p.returncode}: '+p.stderr.decode('utf8','replace')[-800:])
print(f'{n-len(bad)}/{n} cases match')
for i in bad[:int(os.environ.get('CHECK_SHOW','8'))]:print(f'case {i}: input {cl[i][:400]!r}\n  want {a[i][:500]}\n  got  {(o[i] if i<len(o) else "<no output>")[:500]}')
sys.exit(1 if bad or p.returncode else 0)
