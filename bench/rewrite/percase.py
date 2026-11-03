import subprocess,sys,collections,re
SE=re.compile(r'"error":"(Parse error: )?[^"]*"')
def same(o,r): return o==r or (bool(re.search(r' at line \d+ column \d+|^\{"error":"(expected|EOF|invalid|unknown variant|missing field)',r)) and SE.sub('E',o)==SE.sub('E',r))
d,exe=sys.argv[1],sys.argv[2]
c=open(d+'/cases.txt').read().split('\n');c=c[:-1] if c[-1]=='' else c
a=open(d+'/ref.out').read().split('\n')
r=collections.defaultdict(lambda:[0,0,0]);bad=[]
for i,l in enumerate(c):
    p=subprocess.run([exe],input=(l+'\n').encode(),capture_output=True,cwd=d)
    o=p.stdout.decode('utf8','replace').rstrip('\n');k=l.split('\t')[0] if '\t' in l else 'line'
    r[k][0]+=1;r[k][1]+=same(o,a[i]);r[k][2]+=p.returncode!=0
    if not same(o,a[i]): bad.append((i,k,p.stderr.decode()[-150:].strip(),o[:300],a[i][:300]))
print({k:f"{v[1]}/{v[0]}"+(f" crash{v[2]}" if v[2] else "") for k,v in r.items()})
open(d+'/bad.txt','w').write('\n'.join(f"#{i} {k} ERR:{e}\n  he:  {o}\n  ref: {x}" for i,k,e,o,x in bad))
