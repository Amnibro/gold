import json,os,subprocess,sys,time
R=os.path.dirname(os.path.abspath(__file__));d=sys.argv[1];lim=float(sys.argv[2]);cwd=os.path.join(R,d);m=json.load(open(cwd+'/meta.json'))
if subprocess.run([sys.executable,R+'/check.py',d]).returncode:sys.exit(1)
cases=open(cwd+'/'+m['cases'],'rb').read();ts=[]
for _ in range(3):
    t=time.perf_counter();subprocess.run(m['run_he'],shell=True,cwd=cwd,input=cases,capture_output=True,env={**os.environ,'REPS':str(m.get('reps',1))});ts.append(time.perf_counter()-t)
print(f'speed: {min(ts):.3f} s, limit {lim:.3f} s');sys.exit(0 if min(ts)<=lim else 1)
